# A module to extend the Hydrus APO, Collection, and Item classes.
module Hydrus::Delegatable

  # Takes a hash of arrays and calles delegate() accordingly.
  # See one of the usages for an example of the expected hash.
  def setup_delegations(delegations)
    delegations.each do |datastream, delegate_these|
      delegate_these.each do |method_name, is_uniq, *at_fields|
        h = {:to => datastream}
        h.merge!(:at => at_fields) if at_fields.size > 0
        if is_uniq
          h.merge!(:multiple => false)
        else
          h.merge!(:multiple => true)
        end
        delegate(method_name, h)
      end
    end
  end

end
