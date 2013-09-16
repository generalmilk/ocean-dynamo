require 'spec_helper'

# This is temporary
class Parent < OceanDynamo::Base; end
class Child < OceanDynamo::Base; end
class Pet < OceanDynamo::Base; end


# The parent class
class Parent < OceanDynamo::Base
  dynamo_schema(create: true) do
  end
  has_many :children
  has_many :pets
end


# The Child class
class Child < OceanDynamo::Base
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


# Another child class, Pet
class Pet < OceanDynamo::Base
  dynamo_schema(:uuid, create: true) do
  end
  belongs_to :parent
end


class SpaceCadet < OceanDynamo::Base; end;



describe Parent do

  before :all do
    Parent.establish_db_connection
    Child.establish_db_connection
    Pet.establish_db_connection
  end


  it "should be saveable" do
    Parent.create!
  end

  it "should have a .has_many method" do
    Parent.should respond_to :has_many
  end

  it "should require an argument" do
    expect { Parent.has_many() }.to raise_error(ArgumentError)
  end

  it "should know it has a :has_many relation to the Child class" do
    Parent.relates_to(Child).should == :has_many
  end

  it "should know it has a :has_many relation to the Kid class" do
    Parent.relates_to(Pet).should == :has_many
  end

  it "should know it has no relation to the SpaceCadet class" do
    Parent.relates_to(SpaceCadet).should == nil
  end

  it "should have no extra attributes" do
    Parent.new.attributes.should == { 
      "id"=>"", 
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0
    }
  end

  it "child class Child should have one extra attribute" do
    Child.new.attributes.should == {
      "uuid"=>"", "parent_id"=>nil,
      "created_at"=>nil, "updated_at"=>nil, "lock_version"=>0 
    }
  end

  it "should implement #children" do
    p = Parent.new
    p.should respond_to :children
  end


  describe "#children" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      p.children.should == nil
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      children = p.children
      children.should be_an Array
    end

    it "should be instantiatable as instances" do
      Child.create!(parent_id: Parent.create!)
    end

    it "should store and return an array for a persisted Parent" do
      p = Parent.create!
      c1 = Child.create! parent_id: p.id
      c2 = Child.create! parent_id: p.id
      c3 = Child.create! parent_id: p.id
      children = p.children
      children.should include c1
      children.should include c2
      children.should include c3
    end
  end


  describe "#pets" do

    it "should return nil for an unpersisted Parent" do
      p = Parent.new
      p.pets.should == nil
    end

    it "should return an array of Pets for a persisted Parent" do
      p = Parent.create!
      Pet.create! parent_id: p.id
      pets = p.pets
      pets.should be_an Array
      pets.should_not == []
      pets.first.should be_a Pet
    end

    it "should be instantiatable as instances" do
      Pet.create!(parent_id: Parent.create!)
    end

    it "should return an array for a persisted Parent" do
      p = Parent.create!
      c1 = Pet.create! parent_id: p.id  # We build these by hand until
      c2 = Pet.create! parent_id: p.id  # the association proxies are
      c3 = Pet.create! parent_id: p.id  # in place
      pets = p.pets                     # Cache them locally for faster tests
      pets.should include c1
      pets.should include c2
      pets.should include c3
    end
  end


  describe "associations:" do

      before :each do
        Parent.delete_all
        Child.delete_all
        Pet.delete_all
        @homer = Parent.create!
          @bart = Child.create parent_id: @homer.id
          @lisa = Child.create parent_id: @homer.id
          @maggie = Child.create parent_id: @homer.id

        @marge = Parent.create!

        @peter = Parent.create!
          @meg = Child.create! parent_id: @peter.id
          @chris = Child.create! parent_id: @peter.id
          @stewie = Child.create parent_id: @peter.id

        @lois = Parent.create!
          @brian = Pet.create! parent_id: @lois

      end


      describe "writing: " do

        it "should not store arrays containing objects of incompatible type" do
          expect { @homer.pets = [@maggie] }.
            to raise_error(OceanDynamo::AssociationTypeMismatch, "an array element is not a Pet")
        end

        it "should not store non-arrays" do
          expect { @homer.pets = @maggie }.
            to raise_error(OceanDynamo::AssociationTypeMismatch, "not an array or nil")
          expect { @homer.pets = "lalala" }.
            to raise_error(OceanDynamo::AssociationTypeMismatch, "not an array or nil")
        end

        it "should store nil" do
          expect { @homer.pets = nil }.not_to raise_error
        end

      end


      describe "reading:" do

        it "Homer should have three children" do
          @homer.children.length.should == 3
        end

        it "Homer should have no pets" do
          @homer.pets.length.should == 0
        end


        it "Marge should have no children" do
          @marge.children.length.should == 0
        end

        it "Marge should have no pets" do
          @marge.pets.length.should == 0
        end


        it "Peter should have three children" do
          @peter.children.length.should == 3
        end

        it "Peter should have no pets" do
          @peter.pets.length.should == 0
        end


        it "Lois should have no children" do
          @lois.children.length.should == 0
        end

        it "Lois should have one pet" do
          @lois.pets.length.should == 1
        end
      end

  end

end

