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
