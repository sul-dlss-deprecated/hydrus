require 'spec_helper'

describe Ability do

  before(:all) do
    @af = ActiveFedora::Base.new
    @sd = SolrDocument.new
  end

  before(:each) do
    @auth = Hydrus::Authorizable
    @auth.stub(:can_create_collections?).and_return(false)
    @auth.stub(:is_administrator?).and_return(false)
    @obj  = Object.new
    @ab   = Ability.new(@obj)
    @dru  = 'some_pid'
  end

  describe "get_fedora_object()" do
    
    it "if given non-String, just return it" do
      obj = 1234
      @ab.get_fedora_object(obj).should == obj
    end

    it "if given String that is a valid pid, should return fedora object" do
      ActiveFedora::Base.stub(:find).and_return(@af)
      @ab.get_fedora_object(@dru).should == @af
    end

    it "if given String that is not valid pid, should return nil" do
      ActiveFedora::Base.stub(:find) { raise ActiveFedora::ObjectNotFoundError }
      @ab.get_fedora_object(@dru).should == nil
    end

  end

  describe "hydra_default_permissions" do

    before(:each) do
      @ab.stub(:get_fedora_object)
    end

    it ":read should be based on can_read_object?()" do
      [true, false].each do |exp|
        @auth.stub(:can_read_object?).and_return(exp)
        @ab.can?(:read, @dru).should == exp
        @ab.can?(:read, @af).should  == exp
      end
    end

    it ":read for non-String, non-AF types of objects should be false" do
      @ab.can?(:read, 1234).should == false
      @ab.can?(:read, @sd).should  == false
    end

    it ":create_collections should be based on can_create_collections?()" do
      [true, false].each do |exp|
        @auth.stub(:can_create_collections?).and_return(exp)
        @ab = Ability.new(@obj)
        @ab.can?(:create, Hydrus::Collection).should == exp
      end
    end

    it ":create_items_in should be based on can_create_items_in?()" do
      [true, false].each do |exp|
        @auth.stub(:can_create_items_in?).and_return(exp)
        @ab.can?(:create_items_in, @dru).should == exp
      end
    end

    it ":edit should be based on can_edit_object?()" do
      [true, false].each do |exp|
        @auth.stub(:can_edit_object?).and_return(exp)
        @ab.can?(:edit, @dru).should == exp
        @ab.can?(:edit, @af).should  == exp
      end
    end

    it ":edit for non-String, non-AF types of objects should be false" do
      @ab.can?(:edit, 1234).should == false
      @ab.can?(:edit, @sd).should  == false
    end

    it ":review should be based on can_review_item?()" do
      [true, false].each do |exp|
        @auth.stub(:can_review_item?).and_return(exp)
        @ab.can?(:review, @dru).should == exp
        @ab.can?(:review, @af).should  == exp
      end
    end

    it ":destroy should be false" do
      @ab.can?(:destroy, @dru).should == false
      @ab.can?(:destroy, @af).should  == false
      @ab.can?(:destroy, @sd).should  == false
    end

    it "admin abilities should be based on can_act_as_administrator?()" do
      [true, false].each do |exp|
        @auth.stub(:can_act_as_administrator?).and_return(exp)
        @ab = Ability.new(@obj)
        @ab.can?(:list_all_collections, nil).should == exp
        @ab.can?(:view_datastreams, @dru).should == exp
        @ab.can?(:view_datastreams, @af).should  == exp
      end
    end

  end

end
