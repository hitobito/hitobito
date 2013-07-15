class ErrorsController < ApplicationController
  skip_before_filter :authenticate_person!
  skip_authorization_check
end