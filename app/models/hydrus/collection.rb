class Hydrus::Collection < Dor::Collection

  def apo
    @apo ||= (apo_pid ? ActiveFedora::Base.find(apo_pid, :cast => true) : nil)
  end

  private

  def apo_pid
    @apo_pid ||= admin_policy_object_ids.first
  end

end
