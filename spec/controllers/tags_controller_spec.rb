require 'spec_helper'

describe TagsController do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let!(:validation_tags) do
    PersonTags::Validation.tag_names.collect do |t|
      ActsAsTaggableOn::Tag.create!(name: t)
    end
  end

  before { sign_in(top_leader) }

  describe 'GET #index' do
  end

  describe 'POST #create' do
    let(:tag) { ActsAsTaggableOn::Tag.find_by(name: 'supertag42') }

    it 'creates new tag' do
      post :create, params: { acts_as_taggable_on_tag: { name: 'supertag42', taggings_count: 42 } }

      expect(tag).to be_persisted
      expect(tag.taggings_count).to eq(0) # count cannot be set

      expect(response).to redirect_to(tags_path(returning: true))
    end

    it 'user without permission cannot create tags' do
      sign_in(bottom_member)

      expect do
        post :create, params: { acts_as_taggable_on_tag: { name: 'supertag42' } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe 'PUT #update' do
    let!(:tag) { ActsAsTaggableOn::Tag.create!(name: 'supertag42', taggings_count: 4200) }

    it 'does not update tagging count' do
      put :update, params: { id: tag.id, acts_as_taggable_on_tag: { name: 'tag42', taggings_count: 42 } }

      expect(tag.reload.name).to eq('tag42')
      expect(tag.taggings_count).to eq(4200) # count cannot be updated

      expect(response).to redirect_to(tags_path(returning: true))
    end

    it 'does not update validation tags' do
      validation_tags.each do |t|
        name = t.name
        expect do
          put :update, params: { id: t.id, acts_as_taggable_on_tag: { name: 'tag42' } }
        end.to raise_error(CanCan::AccessDenied)

        expect(t.reload.name).to eq(t.name)
      end
    end

    it 'user without permission cannot update tags' do
      sign_in(bottom_member)

      expect do
        put :update, params: { id: tag.id, acts_as_taggable_on_tag: { name: 'tag42' } }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe 'DELETE #destroy' do
    let!(:tag) { ActsAsTaggableOn::Tag.create!(name: 'supertag42', taggings_count: 4200) }

    it 'deletes given tag' do
      expect do
        delete :destroy, params: { id: tag.id }
      end.to change { ActsAsTaggableOn::Tag.count }.by(-1)

      expect(response).to redirect_to(tags_path(returning: true))
    end

    it 'is not possible to delete validation tags' do
      validation_tags.each do |t|
        expect do
          delete :destroy, params: { id: t.id }
        end.to change { ActsAsTaggableOn::Tag.count }.by(0)
          .and raise_error(CanCan::AccessDenied)
      end
    end
  end
end
