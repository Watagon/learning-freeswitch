
FROM mayamatakeshi/freeswitch-dev:1.0.0

RUN <<EOF

cd /usr/local/src/git
git clone https://github.com/MayamaTakeshi/sngrep
cd sngrep/
git checkout mrcp_support
./bootstrap.sh
./configure --enable-unicode --with-pcre
make

ln -s `pwd`/src/sngrep /usr/local/bin/sngrep2

EOF

RUN sed -i -r 's/external_rtp_ip/local_ip_v4/g' /usr/local/freeswitch/conf/sip_profiles/*.xml
RUN sed -i -r 's/external_sip_ip/local_ip_v4/g' /usr/local/freeswitch/conf/sip_profiles/*.xml

RUN sed -i -r 's/<action application="sleep" data="10000"\/>/<action application="sleep" data="500"\/>/' /usr/local/freeswitch/conf/dialplan/default.xml

RUN mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

RUN <<EOF cat > ~/.vimrc
set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.

set shiftwidth=4    " Indents will have a width of 4

set softtabstop=4   " Sets the number of columns for a TAB

set expandtab       " Expand TABs to spaces

execute pathogen#infect()
syntax on
filetype plugin indent on

set background=dark
colorscheme zenburn
EOF


RUN <<EOF
# install zenburn color theme
mkdir -p ~/.vim/colors/
cd ~/.vim/colors/
wget https://raw.githubusercontent.com/jnurmine/Zenburn/de2fa06a93fe1494638ec7b2fdd565898be25de6/colors/zenburn.vim
EOF

