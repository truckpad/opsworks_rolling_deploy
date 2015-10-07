# 
module OpsworksRollingDeploy

  module OutputMethods
    def warn(*strs)
      puts strs.join(' ').yellow
    end

    def info(*strs)
      puts strs.join(' ').blue
    end

  end
end
