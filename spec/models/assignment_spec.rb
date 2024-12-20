# == Schema Information
#
# Table name: assignments
#
#  id              :bigint           not null, primary key
#  attachment_type :string
#  description     :text             not null
#  read_at         :date
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  attachment_id   :integer
#  creator_id      :bigint           not null
#  person_id       :bigint           not null
#
# Indexes
#
#  index_assignments_on_creator_id  (creator_id)
#  index_assignments_on_person_id   (person_id)
#

require "spec_helper"

describe Assignment do
  let(:assignment) { assignments(:printing) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  it "#to_s shows title" do
    expect(assignment.to_s).to eq(assignment.title)
  end

  it "can not change person_id after create" do
    assignment.update!(person_id: top_leader.id)
    assignment.reload
    expect(assignment.person_id).to_not eq(top_leader.id)
  end

  it "can not change creator_id after create" do
    assignment.update!(creator_id: bottom_member.id)
    assignment.reload
    expect(assignment.creator_id).to_not eq(bottom_member.id)
  end

  context "attachment" do
    let(:printer) { Fabricate(:company, email: "printing_company@example.com") }
    let(:new_assignment) { Assignment.new(person: printer, creator: top_leader, title: "Printing", description: "DIN A4") }

    it "prepares attachment for printing after creation" do
      new_assignment.attachment = messages(:letter)
      expect do
        new_assignment.save!
      end.to change { Delayed::Job.count }.by(1)
    end
  end
end
