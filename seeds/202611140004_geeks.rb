# The handouts do not supply a complete geek fixture: these nine are sample data.
Sequel.seed(:development, :test) do
  def run
    Recruitment::Seeds.connection[:geeks].multi_insert([
      { name: 'Peter', stack: 'Ruby Sinatra React', resume: true },
      { name: 'Anna', stack: 'Ruby on Rails', resume: true },
      { name: 'Ivan', stack: 'React Javascript', resume: false },
      { name: 'Maria', stack: 'Node Javascript', resume: true },
      { name: 'Alex', stack: 'CSS HTML', resume: true },
      { name: 'Olga', stack: 'Ruby PostgreSQL', resume: false },
      { name: 'Dmitry', stack: 'React Node', resume: true },
      { name: 'Elena', stack: 'Ruby Sequel', resume: true },
      { name: 'Nikita', stack: 'Javascript HTML', resume: false }
    ])
  end
end
