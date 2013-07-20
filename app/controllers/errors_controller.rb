class ErrorsController < ApplicationController
  skip_before_filter :set_stamper
  skip_before_filter :authenticate_person!
  skip_after_filter :reset_stamper

  skip_authorization_check
end
