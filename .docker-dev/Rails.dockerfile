FROM centos/ruby-26-centos7
ENV RAILS_ENV=development
USER root
COPY . /opt/app-root/src
WORKDIR /opt/app-root/src/hitobito
RUN cp ./Wagonfile.ci ./Wagonfile

RUN bash -c bundle install

CMD [ "bundle", "exec", "rails", "server", "-b", "0.0.0.0" ]
