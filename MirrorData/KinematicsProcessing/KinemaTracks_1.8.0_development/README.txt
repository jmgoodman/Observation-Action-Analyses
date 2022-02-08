Versions

Actual
28.11.2017 KinemaTracks_1.7.4_Stable

Older
27.11.2017 KinemaTracks_1.7.3_MinorChanges
21.11.2017 KinemaTracks_1.7.2_AfterFrezingForWeiAn
17.11.2017 KinemaTracks_1.7.1_AllowParamChangeOnline
02.11.2017 KinemaTracks_1.7.0_Merge_1_6_2_With_1_5_4

Other
KinemaTracks_1.6.2_UpgradeMatlab
KinemaTracks_1.5.4_IntegrateNewThumbAndNewIK
KinemaTracks_1.5.3_RevertChangesAndOtherImprov

TODO: write a better README.txt

There are two important objects, the LHO (local hand object) and the GHO (global hand object).

Some important attributes are:

.fingerjoints: Is a 5x7x3 Matrix with the "joint" positions in the order: finger x joint x XYZ Pos + Quaternion concatenation

Joints are:
1: The sensor position
2-3: Projections on the distal phalanges (position on the distal phalanges, points U and V on the JNE paper)
4,5,6: Estimated positions (T, C, B on the JNE paper)
7: MCP joint (A on the JNE paper)

.lengthsensor: sensor to tip distance? the length of the orientation sensor (the only one with a quaternion that has a real component) on the back of the hand?

Hand side notation:
case 'left': handside = 1;
case 'right': handside = -1;
