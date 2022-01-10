function outstruct = kfilt(neuraldata,kinematicdata,opts)
% fits a kalman filter to predict kinematics from neural data. it outputs the parameters, predictions, and goodness-of-fit estimates.
% behaviour can be modified by adjusting the "opts" input with the makedecodeopts() method.
% NOTE: kinematicdata should just comprise postures. We'll time-shift the kinematics to allow for velocity-like computations.

if nargin < 3
    opts = makedecodeopts(); % default opts
else
    % pass
end

%% step 0: reference (https://en.wikipedia.org/wiki/Kalman_filter)
% models:
% X(t+1) = AX(t) + q(t) (q ~ N(0,Q)) % assume noise covariance and process model are fixed...
% Y(t)   = BX(t) + w(t) (w ~ N(0,W))

% optimal estimates: Xhat and its estimated covariance, P
% also features innovation (delta) and its residual covariance (S)

% Xhat(t+1|t) = AXhat(t|t)
% P(t+1|t) = A*P(t|t)*A' + Q
% delta(t+1) = Y(t+1) - B*Xhat(t+1|t)
% S(t+1) = B*P(t+1|t)*B' + W
% K(t+1) = P(t+1)*B'*inv(S(t+1)) [OPTIMAL Kalman gain for timestep t+1, this changes with changes to the loss function]
% Xhat(t+1|t+1) = Xhat(t+1|t) + K(t+1)*delta(t+1)
% P(t+1|t+1) = (I - K(t+1)*B)*P(t+1|t)

% loss function:
% trace( P(t+1|t+1) )

% reformulation to put in a nice, didactic, bayesian fusion format
% xhatsubx(t) = A*x(t-1) (noise: q ~ N(0,Q) for this timestep, plus the uncertainty accumulated from other timesteps)
% xhatsuby(t) = B*y(t) (noise: w ~ N(0,W))
% Phatsubx(t) = A*Phatfused(t-1)*A' + Q
% Phatsuby(t) = W
% xhatfused(t) = inv( inv(Phatsubx(t)) + inv(Phatsuby(t)) ) * ( inv(Phatsubx(t))*xhatsubx(t) + inv(Phatsuby(t))*xhatsuby(t) )
% Phatfused(t) = inv( inv(Phatsubx(t)) + inv(Phatsuby(t)) )
% 
% what is Phatfused going to trend toward?
% Px(t) = A*Pfused(t-1)*A' + Q
% Py(t) = W
% Pfused(t) = inv( inv( Px(t) ) + inv( Py(t) ) ) = inv( inv(A*Pfused(t-1)*A' + Q) + inv( W ) )
%
% note: Pfused does NOT trend indefinitely toward W. It can't, in fact, because then inv( inv(A*W*A' + Q) + inv(W) ) would need to also equal W, which can only be true if Q is massive.
% however, Pfused does, in theory, converge on a set value. It seems like it SHOULD have a nice closed-form solution given my formulation of the problem, too, but I'm too dumb to figure it out. So, I'll just have an initial estimate of 0 for P and let the closed-form solution "burn in".
% we can use least-squares to estimate Q and W, which in turn tell us what the convergence value of Pfused will be.

%% step 1: devise the models
% B matrix = neural decoding model
% A matrix = kinematic model
% don't use least squares for the A matrix - this requires info that you wouldn't have for online decoding
% instead, use a first-principles Eulerian approach: upcoming postures = previous postures + velocity*dt, upcoming velocities = previous velocities
% IMPORTANT: noise estimates for position coordinates are NOT zero. We're doing this offline after all, so the Kalman filter merely estimates the actual position, and doesn't dictate it (in this sense, we're HANDICAPPED w.r.t. the online case).

numcomps = size(kinematicdata,2); % assume we're working with samples x coordinates here

Kt       = kinematicdata(2:end,:);
Ktminus1 = kinematicdata(1:(end-1),:);
deltaK   = Kt - Ktminus1;

Ktotal      = horzcat(Kt,deltaK);
ncompstotal = size(Ktotal,2);

% hmmmm... I do not enjoy having these imperfect models of what's going on... like, I COULD just have a kinematic model that infers things directly, but then I'd have 0 covariance terms...
% I also do not enjoy not knowing where dynamical 0 lies. For a first-principles model, this isn't such a big deal, but for a model inferred via least squares, this gets thorny.

