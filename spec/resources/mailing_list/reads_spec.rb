require "rails_helper"

RSpec.describe MailingListResource, type: :resource do
  describe "serialization" do
    let!(:mailing_list) { mailing_lists(:leaders) }

    it "works" do
      render
      data = jsonapi_data[0]
      expect(data.id).to eq(mailing_list.id)
      expect(data.jsonapi_type).to eq("mailing_lists")
    end

    context "with service token" do
      ServiceToken::PERMISSIONS.each do |permission|
        context "with #{permission} permission" do
          let(:group) { groups(:top_layer) }
          let(:token) { Fabricate(:service_token, layer: group, permission:, mailing_lists: true) }
          let(:current_scopes) { %w[mailing_lists] }
          let(:ability) { TokenAbility.new(token) }
          let(:data) { jsonapi_data[0] }

          before do
            params[:filter] = {id: {eq: mailing_list.id}}
            render
          end

          context "mailing list in same group" do
            let(:mailing_list) { groups(:top_layer).mailing_lists.create!(name: "list") }

            it "works" do
              expect(data.id).to eq(mailing_list.id)
              expect(data.jsonapi_type).to eq("mailing_lists")
            end
          end

          context "mailing list in same layer" do
            let(:mailing_list) { groups(:top_group).mailing_lists.create!(name: "list") }

            it "works" do
              expect(data.id).to eq(mailing_list.id)
              expect(data.jsonapi_type).to eq("mailing_lists")
            end
          end

          context "mailing list in sub layer" do
            let(:mailing_list) { groups(:bottom_layer_one).mailing_lists.create!(name: "list") }

            it "does not work" do
              expect(data).to be_nil
            end
          end
        end
      end

      context "without mailing_lists scope" do
        let(:group) { groups(:top_layer) }
        let(:token) {
          Fabricate(:service_token, layer: group, permission: :layer_and_below_full,
            mailing_lists: false, people: true)
        }
        let(:current_scopes) { %w[people] }
        let(:ability) { TokenAbility.new(token) }
        let(:data) { jsonapi_data[0] }

        before do
          params[:filter] = {id: {eq: mailing_list.id}}
          render
        end

        context "mailing list in same group" do
          let(:mailing_list) { groups(:top_layer).mailing_lists.create!(name: "list") }

          it "does not work" do
            expect(data).to be_nil
          end
        end

        context "mailing list in same layer" do
          let(:mailing_list) { groups(:top_group).mailing_lists.create!(name: "list") }

          it "does not work" do
            expect(data).to be_nil
          end
        end

        context "mailing list in sub layer" do
          let(:mailing_list) { groups(:bottom_layer_one).mailing_lists.create!(name: "list") }

          it "does not work" do
            expect(data).to be_nil
          end
        end
      end
    end
  end

  describe "filtering" do
    let!(:mailing_list1) { mailing_lists(:leaders) }
    let!(:mailing_list2) { mailing_lists(:members) }

    context "by id" do
      before do
        params[:filter] = {id: {eq: mailing_list2.id}}
      end

      it "works" do
        render
        expect(d.map(&:id)).to eq([mailing_list2.id])
      end
    end
  end

  describe "sorting" do
    describe "by id" do
      let!(:mailing_list1) { mailing_lists(:leaders) }
      let!(:mailing_list2) { mailing_lists(:members) }
      let!(:mailing_list3) { mailing_lists(:top_group) }

      context "when ascending" do
        before do
          params[:sort] = "id"
        end

        it "works" do
          render
          expect(d.map(&:id)).to eq([
            mailing_list1.id,
            mailing_list2.id,
            mailing_list3.id
          ])
        end
      end

      context "when descending" do
        before do
          params[:sort] = "-id"
        end

        it "works" do
          render
          expect(d.map(&:id)).to eq([
            mailing_list3.id,
            mailing_list2.id,
            mailing_list1.id
          ])
        end
      end
    end
  end
end
