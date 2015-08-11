# set up everything required to run rake jobs for hitobito wagons on jenkins

cd hitobito

cp Wagonfile.ci Wagonfile

bundle install --path vendor/bundle

for d in ../hitobito_*; do
  cp Gemfile.lock $d
done

rm -rf tmp/tarantula
