require "spec_helper"

describe Tags::MergeController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  let(:tag1) { Fabricate(:tag) }
  let(:tag2) { Fabricate(:tag) }
  let!(:tag3) { Fabricate(:tag) }

  let!(:tag1_owner) { fabricate_tagged_person([tag1]) }
  let!(:tag2_owner) { fabricate_tagged_person([tag2]) }
  let!(:all_tag_owner) { fabricate_tagged_person([tag1, tag2]) }

  before { sign_in(top_leader) }

  describe "GET #new" do
    it "suggests new tag name based on tagging count" do
      get :new, xhr: true, params: {ids: [tag2.id, tag3.id].join(",")}

      expect(assigns(:name)).to eq tag2.name
      expect(assigns(:tag_names)).to eq [tag3.name, tag2.name].join(", ")
      expect(assigns(:src_tag_ids)).to eq [tag3.id]
    end

    it "is not possible to merge tags without permission" do
      sign_in(bottom_member)

      expect do
        get :new, params: {ids: [tag2.id, tag1.id].join(",")}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "POST #create" do
    it "merges tags" do
      post :create, params: {tags_merge: {src_tag_ids: tag1.id, dst_tag_id: tag2.id, name: tag2.name}}

      expect(tag1_owner.reload.tags.to_a).to eq([tag2])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag2])

      expect(tag2.reload.taggings_count).to eq(3)

      expect(ActsAsTaggableOn::Tag.where(id: tag1.id)).not_to exist

      is_expected.to redirect_to tags_path
      expect(flash[:notice]).to eq "Die Tags wurden erfolgreich zusammengeführt."
    end

    it "merges multiple tags" do
      post :create, params: {tags_merge: {src_tag_ids: [tag3.id, tag1.id].join(","), dst_tag_id: tag2.id, name: tag2.name}}

      expect(tag1_owner.reload.tags.to_a).to eq([tag2])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag2])

      expect(tag2.reload.taggings_count).to eq(3)

      expect(ActsAsTaggableOn::Tag.where(id: tag1.id)).not_to exist
      expect(ActsAsTaggableOn::Tag.where(id: tag3.id)).not_to exist

      is_expected.to redirect_to tags_path

      expect(flash[:notice]).to eq "Die Tags wurden erfolgreich zusammengeführt."
    end

    it "is not possible to merge tags without permission" do
      sign_in(bottom_member)

      expect do
        post :create, params: {tags_merge: {src_tag_ids: tag2.id, dst_tag_id: tag1.id, name: tag2.name}}
      end.to raise_error(CanCan::AccessDenied)

      expect(tag1_owner.reload.tags.to_a).to eq([tag1])
      expect(tag2_owner.reload.tags.to_a).to eq([tag2])
      expect(all_tag_owner.reload.tags.to_a).to eq([tag1, tag2])
    end
  end

  private

  def fabricate_tagged_person(tags)
    person = Fabricate(:person)
    person.update!(tags: tags)
    person
  end
end
