class AppStatus

  def store_ok?
    folder = Rails.root.join('public')
    File.directory?(folder) && File.writable?(folder)
  end

  def code
    @code ||= store_ok? ? :ok : :service_unavailable
  end

end
