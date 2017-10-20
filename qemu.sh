BREAKPOINT="${1}";
LINUX_VERSION="4.8.0";
set -o errexit;
(cd "linux-source-${LINUX_VERSION}" && make -j4 bzImage);
set +o errexit;
if [ ! -L scripts ]; then
	ln -s "linux-source-${LINUX_VERSION}/scripts";
fi;
if [ ! -L vmlinux ]; then
	ln -s "linux-source-${LINUX_VERSION}/vmlinux";
fi;
(cd rootfs && find | cpio -H newc -R root -o) > rootfs.cpio;
qemu-system-x86_64				\
	-append		noapic			\
	-initrd		rootfs.cpio		\
	-kernel		bzImage			\
	-m		256			\
	-s					\
	-vnc		127.0.0.1:0		\
	&
QEMU_PID="${!}";
sleep 1; echo 3 seconds..;
sleep 1; echo 2 seconds..;
sleep 1; echo 1 second...;
vncviewer					\
	"vnc://127.0.0.1:5900"			\
	&
VNC_PID="${!}";
gdb vmlinux					\
	-ex	"break ${BREAKPOINT}"		\
	-ex	"set breakpoint pending on"	\
	-ex	"target remote 127.0.0.1:1234"	\
	-ex	"lx-symbols"			\
	;
wait ${VNC_PID};
for KILL_PID in ${QEMU_PID} ${VNC_PID}; do
	kill "${KILL_PID}" 2>/dev/null; done;

# vim:fileencoding=utf-8 foldmethod=marker noexpandtab sw=8 ts=8 tw=120
