
# TODO: incorporate this into Rubydora.
# Relative to rollback() it Rubydora v0.5.0, it reduced
# test suite runtime from 32 min down to about 8 min.
# Not sure what the two run_hook() calls do or whether they are needed;
# just copied the approach used in Rubydora's rollback().
class Rubydora::Transaction

    # Roll-back transactions by restoring the repository to its
    # original state, based on fixtures that are passed in as a
    # hash, with PIDs and keys and foxml as values.
    def rollback_fixtures(fixtures)
      solr = RSolr.connect(Blacklight.solr_config)
      # Two sets of PIDs:
      #   - everything that was modified
      #   - fixtures that were modified
      aps = Set.new(all_pids)
      fps = Set.new(fixtures.keys) & aps
      # Rollback.
      # Just swallow any exceptions.
      without_transactions do
        # First, purge everything that was modified.
        aps.each do |p|
          begin
            repository.purge_object(pid: p)
            solr.delete_by_id p
            #run_hook(:after_rollback, :pid => p, :method => :ingest)
          rescue
          end
        end
        # Then restore the fixtures to their original state.
        fixtures.each do |p, foxml|
          next unless fps.include?(p)
          begin
            repository.ingest(pid: p, file: foxml)
            $fixture_solr_cache ||= {}
            $fixture_solr_cache[p] ||= begin
              puts " indexing and caching #{p}"
              ActiveFedora::Base.find(p, cast: true).to_solr
            end
            solr.add $fixture_solr_cache[p]
            #run_hook(:after_rollback, :pid => p, :method => :purge_object)
          rescue
          end
        end
      end
      # Wrap up.
      solr.commit
      repository.transactions_log.clear
      true
    end

    # Returns the pids of all objects modified in any way during the transaction.
    def all_pids
      repository.transactions_log.map { |entry| entry.last[:pid] }.uniq
    end

end
