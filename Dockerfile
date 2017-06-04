FROM s4l3h1/docker-snort-barnyard
MAINTAINER Muhammad Salehi <salehi1994@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ENV COVERALLS_TOKEN [secure]
ENV CXX g++
ENV CC gcc
ADD sources.list /etc/apt/sources.list
RUN apt-get update ;\
    apt-get install -y libgdbm-dev libncurses5-dev git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev imagemagick apache2 libyaml-dev libxml2-dev libxslt-dev git libssl-dev imagemagick apache2 libyaml-dev libxml2-dev libxslt-dev git postgresql-server-dev-all libpq-dev vim wget libmysqlclient-dev unzip libmysqlclient-dev;\
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ADD snorby.zip /opt/
ADD ruby-1.9.3-p551.tar.gz /opt/
RUN echo "gem: --no-rdoc --no-ri" > ~/.gemrc 
RUN echo gem: --no-rdoc --no-ri > /etc/gemrc
WORKDIR /opt/
RUN tar -xvzf ruby-1.9.3-p551.tar.gz ;\
cd ruby-1.9.3-p551 ;\
./configure ;\
make -j32 ;\
make install 
RUN gem install wkhtmltopdf
RUN gem install bundler
RUN gem install rails -v '3.2.13'
RUN gem install passenger
RUN gem install public_suffix -v '1.4.6'
RUN mkdir -p /var/www/html/snorby/
RUN unzip -d /var/www/html/snorby snorby.zip
ADD Gemfile /var/www/html/snorby/
ADD Gemfile.lock /var/www/html/snorby/
WORKDIR /var/www/html/snorby
RUN bundle install --full-index --with=production --without=development test
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
