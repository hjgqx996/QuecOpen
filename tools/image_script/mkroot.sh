#!/bin/sh

# Script Tools
MKSQUASHFS="${UBITOOL_DIR}/mksquashfs"
MKUBIFS="mkfs.ubifs"
UBIFS_ARGS="${MKUBIFS_ARGS}"
Squashfs_ARGS="-noappend"
UBINIZE_ARGS="${UBINIZE_ARGS}"

# Script DIR
TOPDIR=""
SRCDIR=""
EXTSDKDIR=""
EXTSDKTOOLS=""
TOOLSFORUBI=""
OUTDIR=""

# Target Name
Rootfs_Squashfs="machine-image-mdm9607.squashfs"
Rootfs_UBI="mdm9607-sysfs.ubi"
Rootfs_UBINIZE="ubinize_system_userdata.cfg"

# Image for DM-Verity
PrivateKey="oem_rootca.key"
Rootfs_HashTree="ql-rootfs-hashtree-mdm9607.bin"
Rootfs_RootHash="ql-rootfs-roothash.bin"
Rootfs_RootHashSign="ql-rootfs-roothash.sign"
Rootfs_RootCert="oem_rootca.cer"

ARGS=`getopt -o "t:s:o:" -l "topdir:,srcdir:,option:" -n "getopt.sh" -- "$@"`
eval set -- "${ARGS}"

Error()
{
    local text="${1}"
    echo -e "\033[31m${1}\033[0m"
}

mkfs_image()
{
    local fstype="${1}"
    local srcdir="${2}"
    local outimg="${3}"
    local imageargs="${4}"
    local ret="1"
    
    case "${fstype}" in
    "squashfs")
        fakeroot ${MKSQUASHFS} "${srcdir}" "${outimg}" ${imageargs}
        ret=$?
        ;;
    "ubifs")
        fakeroot ${MKUBIFS} -r "${srcdir}" -o "${outimg}" ${imageargs}
        ret=$?
        ;;
    *)
        Error "Fstype is not support in the SDK"
        ;;
    esac

    if [ ${ret} -ne 0 ];then
        Error "Generted ubifs image failed! Please check it!!!"
        Error "fs type : ${fstype}"
        Error "root dir: ${srcdir}"
        Error "output  : ${outimg}"
        Error "ubiargs : ${imageargs}"
        exit 1
    fi
    
    return 0
}

mkubimg_rootfs_squashfs()
{
    local srcdir="${1}"
    local imageargs="${2}"
    local outimg="${OUTDIR}/${Rootfs_Squashfs}"
    local rootfs_ubi="${OUTDIR}/${Rootfs_UBI}"
    local ubinizecfg="${OUTDIR}/${Rootfs_UBINIZE}"
    
    cp -f "${TOOLSFORUBI}/${Rootfs_UBINIZE}" "${ubinizecfg}"
    
    mkfs_image "squashfs" "${srcdir}" "${outimg}" "${imageargs}"
    
    if [ "${Quectel_DM}" = "True" ];then
    	hashtreefile="${OUTDIR}/${Rootfs_HashTree}"
    	roothashfile="${OUTDIR}/${Rootfs_RootHash}"
    	roothashsignfile="${OUTDIR}/${Rootfs_RootHashSign}"
    	pkeyfile="${EXTSDKDIR}/dm/${PrivateKey}"
    	
    	cp -f "${EXTSDKDIR}/dm/${Rootfs_RootCert}" "${OUTDIR}"
    	roothash=`veritysetup format ${outimg} "${hashtreefile}" | grep "Root hash"`
    	echo ${roothash} | sed 's/.*Root hash: \(.*\)/\1/g' > "${roothashfile}"
    	openssl rsautl -sign -in ${roothashfile} -inkey ${pkeyfile} -out ${roothashsignfile}
    	cd ${OUTDIR}
    	${UBITOOL_DIR}/ubinize -o ${rootfs_ubi} ${UBINIZE_ARGS} ${ubinizecfg}
    fi
}

Handle_Aargs()
{
	if [ "${Quectel_Selinux}" = "True" ];then
		FileContext="${EXTSDKDIR}/selinux/file_contexts"
		UBIFS_ARGS="${MKUBIFS_ARGS} --selinux ${FileContext}"
		Squashfs_ARGS="-selinux ${FileContext} -noappend"
	fi
}

Handle_ShellArgs()
{
    while true
    do
        case "${1}" in
            -s|--srcdir)
            SRCDIR=`cd ${2} && pwd`
            shift 2;
            ;;
            -t|--topdir)
            TOPDIR=`cd ${2} && pwd`
            EXTSDKDIR="${TOPDIR}/ql-ol-extsdk"
            EXTSDKTOOLS="${EXTSDKDIR}/tools"
            TOOLSFORUBI="${EXTSDKTOOLS}/quectel_ubi"
           	OUTDIR="${TOPDIR}/target"
            shift 2;
            ;;
            --)
            shift;
            break;
            ;;
        esac
    done
}

main()
{
    Handle_ShellArgs $*
    if [ ! -e "${OUTDIR}" ];then
        mkdir -p ${OUTDIR}
    fi
    Handle_Aargs
    mkubimg_rootfs_squashfs "${SRCDIR}" "${Squashfs_ARGS}"
}

main $*

