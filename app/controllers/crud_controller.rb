# Abstract controller providing basic CRUD actions.
# This implementation mainly follows the one of the Rails scaffolding
# controller and responses to HTML and JSON requests. Some enhancements were made to ease extendability.
# Several protected helper methods are there to be (optionally) overriden by subclasses.
# With the help of additional callbacks, it is possible to hook into the action procedures without
# overriding the entire method.
class CrudController < ListController
  include DecoratesBeforeRendering
  prepend_before_filter :entry, except: :index

  delegate :model_identifier, :to => 'self.class'
  
  # Defines before and after callback hooks for create, update, save and destroy actions.
  define_model_callbacks :create, :update, :save, :destroy

  # Defines before callbacks for the render actions. A virtual callback
  # unifiying render_new and render_edit, called render_form, is defined further down.
  define_render_callbacks :show, :new, :edit

  after_save :set_success_notice
  after_destroy :set_success_notice

  helper_method :entry, :full_entry_label
  
  hide_action :model_identifier, :run_callbacks
  
  # Simple helper object to give access to required view helper methods.
  @@helper = Object.new.extend(ActionView::Helpers::TranslationHelper).
                        extend(ActionView::Helpers::OutputSafetyHelper)


  ##############  ACTIONS  ############################################

  # Show one entry of this model.
  #   GET /entries/1
  #   GET /entries/1.json
  def show(&block)
    respond_with(entry, &block)
  end

  # Display a form to create a new entry of this model.
  #   GET /entries/new
  #   GET /entries/new.json
  def new(&block)
    assign_attributes
    respond_with(entry, &block)
  end

  # Create a new entry of this model from the passed params.
  # There are before and after create callbacks to hook into the action.
  # To customize the response, you may overwrite this action and call
  # super with a block that gets the format parameter.
  #   POST /entries
  #   POST /entries.json
  def create(options = {}, &block)
    assign_attributes
    created = with_callbacks(:create, :save) { entry.save }
    respond_with(entry, options.reverse_merge(:success => created), &block)
  end

  # Display a form to edit an exisiting entry of this model.
  #   GET /entries/1/edit
  def edit(&block)
    respond_with(entry, &block)
  end

  # Update an existing entry of this model from the passed params.
  # There are before and after update callbacks to hook into the action.
  # To customize the response, you may overwrite this action and call
  # super with a block that gets the format parameter.
  #   PUT /entries/1
  #   PUT /entries/1.json
  def update(options = {}, &block)
    assign_attributes
    updated = with_callbacks(:update, :save) { entry.save }
    respond_with(entry, options.reverse_merge(:success => updated), &block)
  end

  # Destroy an existing entry of this model.
  # There are before and after destroy callbacks to hook into the action.
  # To customize the response, you may overwrite this action and call
  # super with a block that gets success and format parameters.
  #   DELETE /entries/1
  #   DELETE /entries/1.json
  def destroy(options = {}, &block)
    destroyed = run_callbacks(:destroy) { entry.destroy }
    flash[:alert] ||= error_messages.presence || flash_message(:failure) if !destroyed && request.format == :html
    location = !destroyed && request.env["HTTP_REFERER"].presence || index_url
    respond_with(entry, options.reverse_merge(:success => destroyed, :location => location), &block)
  end

  private

  #############  CUSTOMIZABLE HELPER METHODS  ##############################

  # Main accessor method for the handled model entry.
  def entry
    get_model_ivar || set_model_ivar(params[:id] ? find_entry : build_entry)
  end

  # Creates a new model entry.
  def build_entry
    model_scope.new
  end

  # Sets an existing model entry from the given id.
  def find_entry
    model_scope.find(params[:id])
  end

  # Assigns the attributes from the params to the model entry.
  def assign_attributes
    entry.attributes = model_params 
  end

  # A label for the current entry, including the model name.
  def full_entry_label
    "#{models_label(false)} <i>#{ERB::Util.h(entry)}</i>".html_safe
  end

  # Url of the index page to return to
  def index_url
    polymorphic_url(path_args(model_class), :returning => true)
  end

  # Access params for model
  def model_params
    params[model_identifier]
  end

  private

  # Set a success flash notice when we got a HTML request.
  def set_success_notice
    flash[:notice] ||= flash_message(:success) if request.format == :html
  end

  # Get an I18n flash message, considering _html keys as well.
  # Uses the key {controller_name}.{action_name}.flash.{state}
  # or crud.{action_name}.flash.{state} as fallback.
  def flash_message(state)
    scope = "#{action_name}.flash.#{state}"
    keys = [:"#{controller_name}.#{scope}_html",
            :"#{controller_name}.#{scope}",
            :"crud.#{scope}_html",
            :"crud.#{scope}"]
    @@helper.t(keys.shift, :model => full_entry_label, :default => keys)
  end
  
  # Html safe error messages of the current entry.
  def error_messages
    @@helper.safe_join(entry.errors.full_messages, '<br/>'.html_safe)
  end


  class << self
    # The identifier of the model used for form parameters.
    # I.e., the symbol of the underscored model name.
    def model_identifier
      @model_identifier ||= model_class.name.underscore.to_sym
    end

    # Convenience callback to apply a callback on both form actions (new and edit).
    def before_render_form(*methods)
      before_render_new *methods
      before_render_edit *methods
    end
  end

  # Custom Responder that handles the controller's path_args. 
  # An additional :success option is used to handle action callback chain halts.
  class Responder < ActionController::Responder

    def initialize(controller, resources, options = {})
      super(controller, with_path_args(resources, controller), options)
    end

    private

    # Check whether the resource has errors. Additionally checks the :success option.
    def has_errors?
      options[:success] == false || super
    end

    # Wraps the resources with the path_args for correct nesting.
    def with_path_args(resources, controller)
      resources.size == 1 ? Array(controller.send(:path_args, resources.first)) : resources
    end

  end

  self.responder = Responder

end
