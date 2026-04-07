# frozen_string_literal: true

require "spec_helper"

describe QueryHelpers do
  context "make matcher" do
    describe "basic query counting" do
      it "passes when at least 1 query is made" do
        expect { Person.first }.to make.db_queries
      end

      it "fails when no queries are made" do
        expect do
          expect { "no queries" }.to make.db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block to make at least 1 database query, but made 0/)
      end

      it "passes when exact count matches" do
        expect { Person.limit(2).to_a }.to make(1).db_queries
      end

      it "fails when count doesn't match" do
        expect do
          expect { Person.limit(2).to_a }.to make(5).db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block to make 5 database queries, but made 1/)
      end
    end

    describe "specific query counting with .with()" do
      it "passes when specific query counts match" do
        expect do
          Person.first
          Group.first
        end.to make.db_queries.with("Person Load" => 1, "Group Load" => 1)
      end

      it "allows other queries not specified" do
        expect do
          Person.first
          Group.first
          Role.first
        end.to make.db_queries.with("Person Load" => 1, "Group Load" => 1)
      end

      it "fails when specific query count doesn't match" do
        expect do
          expect do
            Person.first
            Group.first
          end.to make.db_queries.with("Person Load" => 2)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          %r{expected queries: {Person Load: 2}, but got: {Person Load: 1}})
      end

      it "fails when expected query is not executed" do
        expect do
          expect do
            Person.first
          end.to make.db_queries.with("Person Load" => 1, "Group Load" => 1)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          %r{expected queries: {Person Load: 1, Group Load: 1}, but got: {Person Load: 1, Group Load: 0}})
      end
    end

    describe "combining total count and specific queries" do
      it "passes when both total and specific counts match" do
        expect do
          Person.first
          Group.first
        end.to make(2).db_queries.with("Person Load" => 1, "Group Load" => 1)
      end

      it "fails when total count doesn't match even if specific queries match" do
        expect do
          expect do
            Person.first
            Group.first
            Role.first
          end.to make(2).db_queries.with("Person Load" => 1, "Group Load" => 1)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          # rubocop:disable Layout/LineLength
          %r{expected queries: {Person Load: 1, Group Load: 1} \(total: 2\), but got: {Person Load: 1, Group Load: 1} \(total: 3\)})
        # rubocop:enable Layout/LineLength
      end

      it "fails when specific queries don't match even if total matches" do
        expect do
          expect { Person.first and Group.first }
            .to make(2).db_queries.with("Person Load" => 2, "Group Load" => 0)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          %r{expected queries: {Person Load: 2, Group Load: 0}})
      end
    end

    describe "negated matchers" do
      it "passes when no queries are made" do
        expect { "no queries" }.not_to make.db_queries
      end

      it "fails when queries are made" do
        expect do
          expect { Person.first }.not_to make.db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block not to make any database queries, but it did/)
      end

      it "passes when count doesn't match" do
        expect { Person.first }.not_to make(5).db_queries
      end

      it "fails when count matches" do
        expect do
          expect { Person.first }.not_to make(1).db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block not to make 1 database query, but it did/)
      end
    end

    describe "singular vs plural in messages" do
      it "uses 'query' for count of 1" do
        expect do
          expect { Person.first }.to make(2).db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block to make 2 database queries, but made 1/)
      end

      it "uses 'query' in negated message for count of 1" do
        expect do
          expect { Person.first }.not_to make(1).db_query
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError,
          /expected block not to make 1 database query, but it did/)
      end
    end

    describe "db_query alias" do
      it "works with singular db_query" do
        expect { Person.first }.to make(1).db_query
      end
    end

    describe "failure messages" do
      it "includes executed queries in failure message" do
        expect do
          expect { Person.first }.to make(5).db_queries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Executed queries \(1\):/)
      end

      it "shows other queries when using .with() and there's a mismatch" do
        expect do
          expect { Person.first and Group.first and Role.first }
            .to make.db_queries.with("Person Load" => 2)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /also counted following queries:/)
      end
    end
  end

  describe "expect_query_count (legacy)" do
    it "verifies specific query counts" do
      expect_query_count("Person Load" => 1, "Group Load" => 1) do
        Person.first
        Group.first
      end
    end

    it "shows deprecation warning when used for total count" do
      expect(RSpec).to receive(:deprecate).with(
        "expect_query_count { }.to eq(N)",
        hash_including(replacement: "expect { }.to make(N).db_queries")
      )

      expect_query_count { Person.first }.to eq(1)
    end
  end
end
