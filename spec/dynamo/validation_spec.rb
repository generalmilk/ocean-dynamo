require 'spec_helper'

class Bang < OceanDynamo::Base

  primary_key :uuid

  field :uuid
  field :v,    :float,  default: 1.0
  field :must, :string, default: "mandatory"
  field :soso, :string, default: "updated"
  field :hate, :string, default: "exceptional"

  validates :must, presence: true
  validates :soso, presence: { on: :update }
  validates :hate, presence: { strict: true }

end




describe Bang do

  before :all do
    Bang.establish_db_connection
  end

  before :each do
    @i = Bang.new
  end


  it "should be persistable" do
    @i.save!
  end

  it "should require must" do
    @i.must = nil
    @i.save.should == false
    @i.errors[:must].should == ["can't be blank"]
  end

  it "should not require soso at create, but at update" do
    @i.save.should == true
    @i.soso = nil
    @i.save.should == false
    @i.errors[:soso].should == ["can't be blank"]
  end

  it "should raise an exception if hate is nil" do
    @i.hate = false
    expect { @i.save }.to raise_error(ActiveModel::StrictValidationFailed)
  end


  it "valid? should take new_record? into account" do
    @i.valid?.should == true
    @i.save!
    @i.soso = false
    @i.valid?.should == false
  end





end
