module Reality
  describe List do
    def make_page(name)
      double(title: name, infobox: double(name: 'Infobox something')).tap{|d|
        allow(d).to receive(:fetch).and_return(nil)
      }
    end

    def make_data(name)
      double(predicates: {})
    end

    describe :initialize do
      context 'from names' do
        subject{List.new('Argentina', 'Bolivia', 'Chile')}
        it{should all be_an Entity}
        it{should all satisfy{|e| !e.loaded?}}
        it{should be_kind_of Array}
      end

      context 'from entities' do
        subject{List.new(Entity.new('Argentina'), Entity.new('Bolivia'), Entity.new('Chile'))}
        it 'should be coerced' do
          expect(subject.map(&:name)).to eq ['Argentina', 'Bolivia', 'Chile']
        end
      end
    end

    describe :load! do
      subject(:list){List.new('Argentina', 'Bolivia', 'Chile')}
      let(:wikipedia){double}
      before{
        allow(Infoboxer).to receive(:wp).and_return(wikipedia)
      }
      
      context 'when everything is loaded successfully' do
        before{
          expect(wikipedia).to receive(:get_h).
            with('Argentina', 'Bolivia', 'Chile').
            and_return(
              'Argentina' => make_page('Argentina'),
              'Bolivia' => make_page('Bolivia'),
              'Chile' => make_page('Chile')
            )

          expect(Wikidata::Entity).to receive(:by_wikititle).
            with('Argentina', 'Bolivia', 'Chile').
            and_return(
              'Argentina' => make_data('Argentina'),
              'Bolivia' => make_data('Bolivia'),
              'Chile' => make_data('Chile')
            )

          list.load!
        }
        it{should all be_loaded}
      end

      context 'when some entities are not found' do
      end

      context 'when some entity has wikidata_id' do
        subject(:list){List.new(Entity.new('Argentina'), Entity.new('Plurinational State of Bolivia', wikidata_id: 'Q750'))}
        it 'should receive data from wikidata by id' do
          expect(wikipedia).to receive(:get_h).
            with('Argentina').
            and_return('Argentina' => make_page('Argentina')).ordered

          expect(Wikidata::Entity).to receive(:by_wikititle).
            with('Argentina').
            and_return('Argentina' => make_data('Argentina')).ordered

          expect(Wikidata::Entity).to receive(:by_id).
            with('Q750').
            and_return('Q750' => double(predicates: {}, en_wikipage: 'Bolivia')).ordered

          expect(wikipedia).to receive(:get_h).
            with('Bolivia').
            and_return('Bolivia' => make_page('Bolivia')).ordered

          list.load!
        end
      end

      context 'fallback to labels' do
        let(:wikidata){double(predicates: {'P625' => Geo::Coord.new(41.918936, 12.501193)})}
        let(:list){List.new('Piper Club')}
        before{
          expect(wikipedia).to receive(:get_h).
            with('Piper Club').and_return('Piper Club' => nil)
          expect(Wikidata::Entity).to receive(:by_label).
            with('Piper Club').and_return('Piper Club' => wikidata)

          list.load!
        }
        subject{list.first}

        it{should be_loaded}
        its(:wikidata){should_not be_nil}
        its(:wikipage){should be_nil}
      end
    end

    describe :load!, 'real data' do
      subject(:list){List.new('Argentina', 'Bolivia', 'Chile')}
      before{VCR.use_cassette('list-3-countries'){list.load!}}
      it{should all be_loaded}
    end

    describe :inspect do
      context 'not loaded entities' do
        subject{List.new('Argentina', 'Bolivia', 'Chile')}

        its(:inspect){should == '#<Reality::List[Argentina?, Bolivia?, Chile?]>'}
      end

      context 'loaded entities' do
        let(:entity){Entity.new('Argentina').setup!(wikipage: make_page('Argentina'), wikidata: make_data('Argentina'))}
        subject{List.new(entity)}

        its(:inspect){should == '#<Reality::List[Argentina]>'}
      end
    end

    describe 'array-ish behavior' do
      subject(:list){List.new('Argentina', 'Bolivia', 'Chile')}
      
      it 'tries to preserve type' do
        expect(list.select{|e| e.name.include?('a')}).to be_a List
        expect(list.reject{|e| e.name.include?('a')}).to be_a List
        expect(list.sort_by(&:name)).to be_a List
        expect(list.map(&:itself)).to be_a List
        expect(list.first(2)).to be_a List
      end

      it 'drops type when inappropriate' do
        expect(list.first).to be_a Entity
        expect(list.map(&:name)).not_to be_a List
      end
    end

    context 'sparse list (with nils)', :vcr do
      subject(:list){List.new('Argentina', nil, 'Chile')}
      
      its(:inspect){should == '#<Reality::List[Argentina?, nil, Chile?]>'}
      
      it 'should preserve type' do
        expect(list.map(&:itself)).to be_a List
      end

      it 'should be loaded successfully' do
        list.load!
        expect(list.compact).to all be_loaded
      end
    end
  end
end
