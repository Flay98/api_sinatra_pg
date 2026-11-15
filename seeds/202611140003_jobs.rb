Sequel.seed(:development, :test) do
  def run
    Recruitment::Seeds.connection[:jobs].multi_insert([
      { name: 'Sinatra React', place: 'Remote', company_id: 1 },
      { name: 'Ruby React', place: 'Contract', company_id: 2 },
      { name: 'React', place: 'Remote', company_id: 3 },
      { name: 'Node React', place: 'Permanent', company_id: 1 },
      { name: 'Ruby on Rails', place: 'Remote', company_id: 4 },
      { name: 'Node', place: 'Permanent', company_id: 4 },
      { name: 'Javascript CSS HTML', place: 'Permanent', company_id: 4 }
    ])
  end
end
