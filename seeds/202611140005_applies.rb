Sequel.seed(:development, :test) do
  def run
    Recruitment::Seeds.connection[:applies].multi_insert([
      { job_id: 1, geek_id: 1, read: true, invited: false },
      { job_id: 2, geek_id: 3, read: false, invited: false },
      { job_id: 1, geek_id: 2, read: true, invited: true },
      { job_id: 3, geek_id: 1, read: false, invited: false }
    ])
  end
end
