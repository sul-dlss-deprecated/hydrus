require 'spec_helper'

describe HyTime, type: :model do
  it 'should be able to exercise HyTime.now' do
    expect(HyTime.now).to be_kind_of(DateTime)
  end

  HyTime::DT_FORMATS.keys.each do |f|
    it "should be able to exercise the generated #{f} method" do
      s1 = HyTime.send(f)
      s2 = HyTime.send("now_#{f}")
      expect(s1).to be_instance_of(String)
      expect(s2).to be_instance_of(String)
    end
  end

  describe 'HyTime.formatted()' do
    it 'should get expected formatted datetimes using either a String or a DateTime' do
      # Create a time as a String and as a DateTime.
      pf  = :datetime_full
      dt1 = '2000-01-02T03:04:05.006Z'
      dt2 = DateTime.strptime(dt1, HyTime::DT_FORMATS[pf])
      # Expected formatted strings.
      exp = {
        # Back-end formats: in UTC.
        :date             => '2000-01-02',
        :time             => '03:04:05Z',
        :datetime         => '2000-01-02T03:04:05Z',
        pf                => dt1,
        # Display formats should be 8 hours in the past relative to UTC.
        :date_display     => '2000-01-01',
        :time_display     => '7:04 pm',
        :datetime_display => '2000-01-01 7:04 pm',
      }
      exp.each do |f, e|
        # String, with and without a :parse format.
        expect(HyTime.formatted(dt1, parse: pf, format: f)).to eq(e)
        expect(HyTime.formatted(dt1, format: f)).to eq(e)
        # DateTime.
        expect(HyTime.formatted(dt2, format: f)).to eq(e)
      end
    end

    it 'should use :datetime as the default output format' do
      dt = '2000-01-02T03:04:05Z'
      expect(HyTime.formatted(dt)).to eq(dt)
      expect(HyTime.formatted(dt, format: :time_display)).to  eq('7:04 pm')
      expect(HyTime.formatted('2000-01-02', parse: :date)).to eq('2000-01-02T00:00:00Z')
    end

    it 'should return empty string if given a blank value' do
      expect(HyTime.formatted(nil)).to eq('')
      expect(HyTime.formatted('')).to  eq('')
    end

    context 'when :from_localzone is set' do
      let(:dt) { '2000-01-02' }
      before do
        # Force Pacific time
        allow(DateTime).to receive(:local_offset).and_return((-8 * 60 * 60).to_r / 86400)
      end
      subject { HyTime.formatted(dt, from_localzone: fltz) }

      context 'when false' do
        let(:fltz) { false }
        it { is_expected.to eq('2000-01-02T00:00:00Z') }
      end

      context 'when true' do
        let(:fltz) { true }
        it { is_expected.to eq('2000-01-02T08:00:00Z') }
      end
    end
  end

  describe '#is_well_formed_datetime' do
    it 'validates whether the string is formatted like a valid timestamp' do
      expect(HyTime.is_well_formed_datetime(nil)).to eq(false)
      expect(HyTime.is_well_formed_datetime('')).to eq(false)
      expect(HyTime.is_well_formed_datetime('  ')).to eq(false)
      expect(HyTime.is_well_formed_datetime('2000-01-01')).to eq(true)
      expect(HyTime.is_well_formed_datetime('2000-02-31')).to eq(false)
      expect(HyTime.is_well_formed_datetime('2000-01-02T07:00:00Z')).to eq(true)
    end
  end
end
