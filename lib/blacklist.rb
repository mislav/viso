module Blacklist
  def self.registered(subject)
    Blacklister.new(subject).inject
  end

  class Blacklister < SimpleDelegator
    def inject
      before do
        ENV['BLACKLISTED_IPS'].to_s.split(',').each do |ip|
          if ip == request.ip
            Metriks.meter('blacklisted').mark
            puts "Blacklisted: #{ip}"
            halt 404
          end
        end
      end
    end
  end
end
