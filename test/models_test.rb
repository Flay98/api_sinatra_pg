# frozen_string_literal: true

require_relative 'test_helper'

class ModelsTest < DatabaseTest
  include Recruitment

  def test_seed_counts
    assert_equal [4, 7, 9, 4], [Company.count, Job.count, Geek.count, Apply.count]
  end

  def test_company_has_jobs_and_job_has_company
    assert_equal [1, 4], Company[1].jobs.map(&:id).sort
    assert_equal 'MoGo', Job[1].company.name
  end

  def test_applies_associations_in_both_directions
    assert_equal 1, Apply[1].job.id
    assert_equal 1, Apply[1].geek.id
    assert_equal [1, 3], Job[1].applies.map(&:id).sort
    assert_equal [1, 4], Geek[1].applies.map(&:id).sort
    assert_equal [1, 2], Job[1].geeks.map(&:id).sort
    assert_equal [1, 3], Geek[1].jobs.map(&:id).sort
  end

  def test_required_text_attributes
    [Company.new(name: ' ', location: 'London'), Job.new(name: '', place: 'Remote', company_id: 1),
     Geek.new(name: 'Peter', stack: '')].each do |record|
      refute record.valid?
      assert_raises(Sequel::ValidationFailed) { record.save }
    end
  end

  def test_required_references
    refute Job.new(name: 'Ruby', place: 'Remote').valid?
    refute Apply.new(job_id: 1).valid?
    refute Apply.new(geek_id: 1).valid?
  end

  def test_references_must_exist
    refute Job.new(name: 'Ruby', place: 'Remote', company_id: 2_000_000_000).valid?
    refute Apply.new(job_id: 2_000_000_000, geek_id: 1).valid?
    refute Apply.new(job_id: 1, geek_id: 2_000_000_000).valid?
  end

  def test_boolean_defaults_and_false_validation
    geek = Geek.create(name: 'Test', stack: 'Ruby')
    assert_equal false, geek.resume
    apply = Apply.create(job_id: 1, geek_id: geek.id)
    assert_equal false, apply.read
    assert_equal false, apply.invited
    apply.update(read: true, invited: true)
    assert apply.read
    assert apply.invited
    refute Geek.new(name: 'X', stack: 'Ruby', resume: nil).valid?
    refute Apply.new(job_id: 1, geek_id: 1, read: nil).valid?
  end

  def test_timestamps_and_serialization
    company = Company.create(name: 'New', location: 'City')
    assert_instance_of Time, company.created_at
    assert_instance_of Time, company.updated_at
    assert_equal %i[id name location].sort, company.to_api.keys.sort
    assert_match(/\d{4}-\d{2}-\d{2}T/, company.to_detail[:created_at])
  end

  def test_name_location_and_dataset_chaining
    assert_equal [1], Company.by_name('mo').by_location('ne').select_map(:id)
    assert_equal [2, 4], Company.by_location('LONDON').order(:id).select_map(:id)
    assert_equal [], Company.by_name('Q').by_location('London').all
    assert_equal 4, Company.by_name(nil).count
  end

  def test_job_scopes
    assert_equal [1, 3, 5], Job.place('remo').order(:id).select_map(:id)
    assert_equal [2, 5], Job.by_name('ruby').order(:id).select_map(:id)
    assert_equal [1, 4], Job.company_jobs(1).order(:id).select_map(:id)
    assert_equal [1, 4], Company.company_jobs('mo').select_map(:id)
    assert_equal [1, 4], Job.by_company_name('mogo').order(:id).select_map(:id)
  end

  def test_read_and_unread_scopes
    assert_equal [1, 3], Apply.read.order(:id).select_map(:id)
    assert_equal [2, 4], Apply.unread.order(:id).select_map(:id)
  end

  def test_foreign_keys_and_checks_are_enforced_by_postgres
    assert_raises(Sequel::ForeignKeyConstraintViolation) do
      TEST_DB.transaction(savepoint: true) { TEST_DB[:jobs].insert(name: 'X', place: 'Y', company_id: 2_000_000_000) }
    end
    assert_raises(Sequel::CheckConstraintViolation) do
      TEST_DB.transaction(savepoint: true) { TEST_DB[:companies].insert(name: ' ', location: 'Y') }
    end
    exception = assert_raises(Sequel::DatabaseError) do
      TEST_DB.transaction(savepoint: true) { Company[1].destroy }
    end
    assert_instance_of PG::RestrictViolation, exception.wrapped_exception
  end
end
