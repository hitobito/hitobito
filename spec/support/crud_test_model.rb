# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A dummy model used for general testing.
class CrudTestModel < ActiveRecord::Base #:nodoc:

  include DatetimeAttribute
  datetime_attr :last_seen

  attr_protected nil


  belongs_to :companion, class_name: 'CrudTestModel'
  has_and_belongs_to_many :others, class_name: 'OtherCrudTestModel'
  has_many :mores, class_name: 'OtherCrudTestModel', foreign_key: :more_id

  before_destroy :protect_if_companion

  validates :name, presence: true
  validates :birthdate, timeliness: { type: :date, allow_blank: true }
  validates :rating, inclusion: { in: 1..10 }

  default_scope order('name')

  def to_s
    name
  end

  def chatty
    remarks.size
  end

  def klass
    self.class
  end

  private

  def protect_if_companion
    if companion.present?
      errors.add(:base, 'Cannot destroy model with companion')
      false
    end
  end

end

class CrudTestModelDecorator < Draper::Base
  decorates :crud_test_model
end

class OtherCrudTestModel < ActiveRecord::Base #:nodoc:

  attr_protected nil

  has_and_belongs_to_many :others, class_name: 'CrudTestModel'
  belongs_to :more, foreign_key: :more_id, class_name: 'CrudTestModel'

  def to_s
    name
  end
end

# Controller for the dummy model.
class CrudTestModelsController < CrudController #:nodoc:
  HANDLE_PREFIX = 'handle_'

  self.search_columns = [:name, :whatever, :remarks]
  self.sort_mappings = { chatty: 'length(remarks)' }

  skip_authorize_resource
  skip_authorization_check

  decorates :crud_test_model, :crud_test_models

  before_create :possibly_redirect
  before_create :handle_name
  before_destroy :handle_name

  before_render_new :possibly_redirect
  before_render_new :set_companions

  attr_reader :called_callbacks
  attr_accessor :should_redirect

  hide_action :called_callbacks, :should_redirect, :should_redirect=

  # don't use the standard layout as it may require different routes
  # than just the test route for this controller
  layout false

  def index
    super do |format|
      format.js { render text: 'index js'}
    end
  end

  def show
    super do |format|
      format.html { render text: 'custom html' } if entry.name == 'BBBBB'
    end
  end

  def create
    super do |format|
      flash[:notice] = 'model got created' if entry.persisted?
    end
  end

  private

  def list_entries
    entries = super
    if params[:filter]
      entries = entries.where(['rating < ?', 3]).except(:order).order('children DESC')
    end
    entries
  end

  private

  # custom callback
  def handle_name
    if entry.name == 'illegal'
      flash[:alert] = 'illegal name'
      false
    end
  end

  # create callback methods that record the before/after callbacks
  [:create, :update, :save, :destroy].each do |a|
    callback = "before_#{a.to_s}"
    send(callback.to_sym, :"#{HANDLE_PREFIX}#{callback}")
    callback = "after_#{a.to_s}"
    send(callback.to_sym, :"#{HANDLE_PREFIX}#{callback}")
  end

  # create callback methods that record the before_render callbacks
  [:index, :show, :new, :edit, :form].each do |a|
    callback = "before_render_#{a.to_s}"
    send(callback.to_sym, :"#{HANDLE_PREFIX}#{callback}")
  end

  # handle the called callbacks
  def method_missing(sym, *args)
    called_callback(sym.to_s[HANDLE_PREFIX.size..-1].to_sym) if sym.to_s.starts_with?(HANDLE_PREFIX)
  end

  # callback to redirect if @should_redirect is set
  def possibly_redirect
    redirect_to action: 'index' if should_redirect && !performed?
    !should_redirect
  end

  def set_companions
    @companions = CrudTestModel.all conditions: { human: true }
  end

  # records a callback
  def called_callback(callback)
    @called_callbacks ||= []
    @called_callbacks << callback
  end

  def authorize_class
    # nada
  end

end

REGEXP_ROWS = /<tr.+?<\/tr>/m
REGEXP_HEADERS = /<th.+?<\/th>/m
REGEXP_SORT_HEADERS = /<th.*?><a .*?sort_dir=asc.*?>.*?<\/a><\/th>/m
REGEXP_ACTION_CELL = /<td class=\"action\"><a href.+?<\/a><\/td>/m


# A simple test helper to prepare the test database with a CrudTestModel model.
# This helper is used to test the CrudController and various helpers
# without the need for an application based model.
module CrudTestHelper

  # Controller helper methods for the tests

  def model_class
    CrudTestModel
  end

  def controller_name
    'crud_test_models'
  end

  def action_name
    'index'
  end

  def params
    {}
  end

  def path_args(entry)
    entry
  end

  def sortable?(attr)
    true
  end

  def h(text)
    ERB::Util.h(text)
  end

  private

  # Sets up the test database with a crud_test_models table.
  # Look at the source to view the column definition.
  def setup_db
    without_transaction do
      silence_stream(STDOUT) do
        create_crud_test_models_table
        create_other_crud_test_models_table
        create_crud_test_models_other_crud_test_models
      end
      CrudTestModel.reset_column_information
    end
  end

  def create_crud_test_models_table
    ActiveRecord::Base.connection.create_table :crud_test_models, force: true do |t|
      t.string   :name, null: false, limit: 50
      t.string   :password
      t.string   :whatever
      t.integer  :children
      t.integer  :companion_id
      t.float    :rating
      t.decimal  :income, precision: 14, scale: 2
      t.date     :birthdate
      t.time     :gets_up_at
      t.datetime :last_seen
      t.boolean  :human, default: true
      t.text     :remarks

      t.timestamps
    end
  end

  def create_other_crud_test_models_table
    ActiveRecord::Base.connection.create_table :other_crud_test_models, force: true do |t|
      t.string   :name, null: false, limit: 50
      t.integer  :more_id
    end
  end

  def create_crud_test_models_other_crud_test_models
    ActiveRecord::Base.connection.create_table :crud_test_models_other_crud_test_models, force: true do |t|
      t.belongs_to :crud_test_model
      t.belongs_to :other_crud_test_model
    end
  end

  # Removes the crud_test_models table from the database.
  def reset_db
    c = ActiveRecord::Base.connection
    [:crud_test_models, :other_crud_test_models, :crud_test_models_other_crud_test_models].each do |table|
      if c.table_exists?(table)
        c.drop_table(table) rescue nil
      end
    end
  end

  # Creates 6 dummy entries for the crud_test_models table.
  def create_test_data
    (1..6).inject(nil) { |prev, i| create(i, prev) }
    (1..6).each { |i| create_other(i) }
  end

  # Fixture-style accessor method to get CrudTestModel instances by name
  def crud_test_models(name)
    CrudTestModel.find_by_name(name.to_s)
  end

  def with_test_routing
    with_routing do |set|
      set.draw { resources :crud_test_models }
      # used to define a controller in these tests
      set.default_url_options = { controller: 'crud_test_models' }
      yield
    end
  end

  def special_routing
    controller = @controller || controller  # test:unit uses instance variable, rspec the method
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { resources :crud_test_models }

    _routes = @routes

    controller.singleton_class.send(:include, _routes.url_helpers)
    controller.view_context_class = Class.new(controller.view_context_class) do
      include _routes.url_helpers
    end
  end

  def create(index, companion)
    c = str(index)
    CrudTestModel.create!(name: c,
                          children: 10 - index,
                          companion: companion,
                          rating: "#{index}.#{index}".to_f,
                          income: 10000000 * index + 0.1 * index,
                          birthdate: "#{1900 + 10 * index}-#{index}-#{index}",
                          # store entire date to avoid time zone issues
                          gets_up_at: RUBY_VERSION.include?('1.9.') ?
                                            Time.local(2000, 1, 1, index, index) :
                                            Time.utc(2000, 1, 1, index, index),
                          last_seen: "#{2000 + 10 * index}-#{index}-#{index} 1#{index}:2#{index}",
                          human: index % 2 == 0,
                          remarks: "#{c} #{str(index + 1)} #{str(index + 2)}\n" * (index % 3 + 1))
  end

  def create_other(index)
    c = str(index)
    others = CrudTestModel.all[index..(index + 2)]
    OtherCrudTestModel.create!(name: c, other_ids: others.collect(&:id), more_id: others.first.try(:id))
  end

  def str(index)
     (index + 64).chr * 5
  end

  # hack to avoid ddl in transaction issues with mysql.
  def without_transaction
    c = ActiveRecord::Base.connection
    start_transaction = false
    if c.adapter_name.downcase.include?('mysql') && c.open_transactions > 0
      # in transactional tests, we may simply rollback
      c.execute('ROLLBACK')
      start_transaction = true
    end

    yield

    c.execute('BEGIN') if start_transaction
  end

end
