FROM mayamatakeshi/freeswitch-dev:1.0.0

ARG user_name
ARG git_user_name
ARG git_user_email

ARG USER_UID=1000
ARG USER_GID=$USER_UID

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


SHELL ["/bin/bash", "--login", "-c"]

# Create the user
RUN groupadd --gid $USER_GID $user_name \
    && useradd --uid $USER_UID --gid $USER_GID -m $user_name

RUN echo $user_name ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$user_name \
    && chmod 0440 /etc/sudoers.d/$user_name

RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
RUN apt install -y tshark

RUN mkdir /mnt/freeswitch_storage
RUN chown $user_name /mnt/freeswitch_storage

USER $user_name

RUN echo "set-option -g default-shell /bin/bash" >> ~/.tmux.conf

ENV TERM=xterm

RUN git config --global user.email $git_user_email
RUN git config --global user.name $git_user_name

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
 
RUN . ~/.nvm/nvm.sh && nvm install v21.7.0

RUN . ~/.nvm/nvm.sh && npm install -g yarn

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
# install vim zenburn color theme
mkdir -p ~/.vim/colors/
cd ~/.vim/colors/
wget https://raw.githubusercontent.com/jnurmine/Zenburn/de2fa06a93fe1494638ec7b2fdd565898be25de6/colors/zenburn.vim
EOF

RUN <<EOF cat >> ~/.bashrc
export LANG=C.UTF-8
export PS1='\u@\h:\W\$ '
export TZ=Asia/Tokyo
export TERM=xterm-256color
. ~/.nvm/nvm.sh
EOF
