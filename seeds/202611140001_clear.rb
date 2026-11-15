Sequel.seed(:development, :test) do
  def run
    # No CASCADE: an unexpected dependency must prevent deletion.
    Recruitment::Seeds.connection.run('TRUNCATE TABLE applies, jobs, geeks, companies RESTART IDENTITY')
  end
end
