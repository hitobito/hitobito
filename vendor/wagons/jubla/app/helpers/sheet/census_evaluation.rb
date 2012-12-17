module Sheet
  class CensusEvaluation < Base
    self.parent_sheet = Sheet::Group
    
    class Federation < Sheet::CensusEvaluation
    end
    
    class State < Sheet::CensusEvaluation
    end
    
    class Flock < Sheet::CensusEvaluation
    end
  end
end