#!/usr/bin/env bash 

#
# Install the dependencies needed to run AMDTK.
# 

# We avoid symbolic links as it may confuses the installation process.
amdtk_root=$(pwd -P)

anaconda_path=
env_name="py35_amdtk"

while getopts ":e:hp:" opt; do
    case $opt in
        e) 
            env_name=$OPTARG
            ;;
        p)
            anaconda_path=$OPTARG
            ;;
        h)
            echo "usage: $0 [OPTIONS]"
            echo ""
            echo "Install the dependencies needed to run AMDTK and some"
            echo "recipes."
            echo ""
            echo "Options:"
            echo "  -e NAME     Anaconda environment name. Default: $env_name."
            echo "  -h          Show this message."
            echo "  -p PATH     Path to an existing Anaconda distribution. If"
            echo "              not provided a Miniconda distribution will be"
            echo "              installed."
            exit 0
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Directory where we will install the external tools and python (miniconda)
mkdir -p $amdtk_root/extras

if [ ! -d $anaconda_path ]; then
    echo "Installing Miniconda 3"

    # Check the architecture of the machine.
    arch=`uname -m`
    case $arch in 
        x86_64)
            miniconda_url="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
            ;;
        x86)
            miniconda_url="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86.sh"
            ;;
        *)
            echo "Unknown architecture. You will have to install Anaconda on your own."
            exit 1
            ;;
    esac

    # Download miniconda. 
    install_script="extras/Miniconda3-latest-Linux-$arch.sh"
    if [ ! -e $install_script ]; then
        wget -P $amdtk_root/extras $miniconda_url
    else
        echo Miniconda installer is already downloaded.
    fi

    # Install Miniconda 3. AMDTK is developed using python 3. To avoid any 
    # conflict with any existing python environment we install Miniconda and 
    # create a specific environment for AMDTK. If you want to use your own 
    # python distribution, skip this step and change the paths accordingly.
    if [ ! -e $amdtk_root/extras/miniconda3 ]; then
        chmod +x $install_script
        ./$install_script -b -p $amdtk_root/extras/miniconda3
    else
        echo Miniconda is already installed.
    fi
fi

# Set the path to the correct python distribution for the the rest of the 
# installation.
unset PYTHONPATH
export PATH=$anaconda_path/bin:$PATH

# We create a specific environment for AMDTK if it doesn't exists.
if [ -z "`conda env list | grep $env_name`" ]; then
    conda env create --name $env_name python=3 -f $amdtk_root/py35_amdtk.yml
fi

# Activate the new environment to install other dependencies.
source activate $env_name

# set prefix for installations
prefix="$anaconda_path"/envs/"$env_name"

# Create the path.sh file to use the newly created environment.
cp $amdtk_root/path_template.sh $amdtk_root/extras/path.sh
echo >> $amdtk_root/extras/path.sh
echo "# Setting python environment." >> $amdtk_root/extras/path.sh
echo "unset PYTHONPATH" >> $amdtk_root/extras/path.sh
echo "export PYTHONPATH=$amdtk_root" >> $amdtk_root/extras/path.sh
echo "export PATH=$amdtk_root/scripts:$amdtk_root/extras/sph2pipe_v2.5:$amdtk_root/extras/bin:$anaconda_path/bin:\$PATH" >> $amdtk_root/extras/path.sh
echo >> $amdtk_root/extras/path.sh
echo "# Adding the tools directory." >> $amdtk_root/extras/path.sh
echo "export PATH=$amdtk_root/tools:\$PATH" >> $amdtk_root/extras/path.sh
echo "" >> $amdtk_root/extras/path.sh
echo "# Selecting the AMDTK environment." >> $amdtk_root/extras/path.sh
echo "export PATH=$anaconda_path/envs/$env_name/bin:\$PATH" >> $amdtk_root/extras/path.sh
echo "" >> $amdtk_root/extras/path.sh
echo "#Extending LD_LIBRARY_PATH" >> $amdtk_root/extras/path.sh
echo "export LD_LIBRARY_PATH=$prefix/lib:\$LD_LIBRARY_PATH" >> $amdtk_root/extras/path.sh

#echo "source activate $env_name" >> $amdtk_root/extras/path.sh

# Install the recipes.
echo -n "Copying 'path.sh' file into recipes' directory... "
# Mandarin LDC2016E108 recipe
mkdir -p $amdtk_root/recipes/CHN_DEV_20160831
cp $amdtk_root/extras/path.sh $amdtk_root/recipes/CHN_DEV_20160831

# Uyghur IL3_DEV_20160831 recipe
mkdir -p $amdtk_root/recipes/IL3_DEV_20160831
cp $amdtk_root/extras/path.sh $amdtk_root/recipes/IL3_DEV_20160831
echo done

