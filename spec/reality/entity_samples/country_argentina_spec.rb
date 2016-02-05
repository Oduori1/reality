module Reality
  describe Entity, 'samples' do
    describe 'Country: Argentina' do
      before(:all){
        # parsed only once - faster tests
        VCR.use_cassette('Country-Argentina'){
          @country = Reality::Country.new('Argentina', load: true) 
        }
      }
      
      subject(:country){@country}
      
      describe 'basics' do
        its(:name){should == 'Argentina'}
        its(:long_name){should == 'Argentine Republic'}

        its(:iso2_code){should == 'AR'}
        its(:iso3_code){should == 'ARG'}
        its(:tld){should == '.ar'}
        its(:calling_code){should == '+54'}
        its(:utc_offset){should == -3}
      end

      describe 'measures' do
        its(:area){should == Reality::Measure(2_780_400, 'km²')}
        its(:population){should == Reality::Measure(43_417_000, 'person')}
        its(:gdp_ppp){should == Reality::Measure(964_279_000_000, '$')}
        its(:gdp_nominal){should == Reality::Measure(537_659_972_702, '$')}
      end

      describe 'geo' do
        its(:coord){should == Geo::Coord.from_dms([34,'S'], [64,'W'])}
      end

    end
  end
end
