Sequel.seed(:development, :test) do
  def run
    Recruitment::Seeds.connection[:companies].multi_insert([
      { name: 'MoGo', location: 'New York' },
      { name: 'Wirkkle', location: 'London' },
      { name: 'Artesis', location: 'Saint-Petersburg' },
      { name: 'BuildEmpire', location: 'London' }
    ])
  end
end
