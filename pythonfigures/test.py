class Animal:
    def __init__(self):
        self.legs = 4
        self.arms = 0
    
    def count_limbs(self) -> int:
        return self.legs + self.arms
    
    def count_toes(self) -> int:
        return self.count_limbs()*5
    
class Stegosaurus(Animal):
    def __init__(self):
        super().__init__()
        print(self.count_toes()) # okay, so this bad boy has already propagated the overridden method throughout all of its parent calls by this point
        
    def count_limbs(self) -> int:
        # a mace-like tail counts as a limb, we decided
        # with the protrusions counting as toes
        return self.legs + self.arms + 1
    
if __name__=="__main__":
    A = Animal()
    print(A.count_toes())
    Stegosaurus()