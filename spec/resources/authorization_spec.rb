require "spec_helper"

describe "Resource authorization", type: :resource do
  before do
    stub_const('PersonTestResource', Class.new(ApplicationResource) do
      self.model = Person
      self.type = 'people'
      attribute :first_name, :string, writable: true
      attribute :last_name, :string, writable: true
    end)
  end

  after { Graphiti.resources.delete(PersonTestResource) }

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "people",
          attributes: {
            first_name: "Test First Name",
            last_name: "Test Last Name"
          }
        }
      }
    end

    let(:instance) do
      PersonTestResource.build(payload)
    end

    it "permits create" do
      set_ability { can :create, Person }

      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Person.count }.by(1)
    end

    it "denies create" do
      set_ability {}

      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to raise_error(CanCan::AccessDenied).and not_change { Person.count }
    end

    it "permits create based on attribute" do
      set_ability { can :create, Person, :first_name }

      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { Person.count }.by(1)
    end

    it "denies create based on attribute" do
      set_ability { can :create, Person, :email }

      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to raise_error(CanCan::AccessDenied).and not_change { Person.count }
    end
  end

  describe "updating" do
    let!(:person) { Fabricate(:person, first_name: "Boring old name") }

    let(:payload) do
      {
        id: person.id.to_s,
        data: {
          id: person.id.to_s,
          type: "people",
          attributes: {
            first_name: "Fancy name"
          }
        }
      }
    end

    let(:instance) do
      PersonTestResource.find(payload)
    end

    it "permits update" do
      set_ability { can :update, Person }

      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.first_name }.from("Boring old name").to("Fancy name")
    end

    it "denies update" do
      set_ability {}

      expect {
        instance.update_attributes
      }.to raise_error(CanCan::AccessDenied).and not_change { person.reload.first_name }
    end

    it "permits update based on attribute" do
      set_ability { can :update, Person, :first_name }

      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.first_name }.from("Boring old name").to("Fancy name")
    end

    it "denies update based on attribute" do
      set_ability { can :update, Person, :email }

      expect {
        expect(instance.update_attributes).to eq(true)
      }.to raise_error(CanCan::AccessDenied).and not_change { person.reload.first_name }
    end

    it "permits update based on attribute value" do
      set_ability { can :update, Person, first_name: "Boring old name" }

      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.first_name }.from("Boring old name").to("Fancy name")
    end

    it "denies update based on attribute value" do
      set_ability { can :update, Person, first_name: "Some other name" }

      expect {
        expect(instance.update_attributes).to eq(true)
      }.to raise_error(CanCan::AccessDenied).and not_change { person.reload.first_name }
    end
  end
end
