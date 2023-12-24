#include <ulib.h>
#include <unistd.h>
#include <file.h>
#include <stat.h>

int main(int argc, char *argv[]);

static int
initfd(int fd2, const char *path, uint32_t open_flags) {
    int fd1, ret;
    if ((fd1 = open(path, open_flags)) < 0) {
        return fd1;  // 打开文件失败，返回错误
    }
    if (fd1 != fd2) {
        close(fd2);           // 关闭目标文件描述符
        ret = dup2(fd1, fd2); // 复制 fd1 到 fd2，即使 fd2 已经打开，dup2 会先关闭 fd2，然后进行复制
        close(fd1);           // 关闭原始的文件描述符
    }
    return ret; // 返回操作结果
}


void
umain(int argc, char *argv[]) {
    int fd;
    if ((fd = initfd(0, "stdin:", O_RDONLY)) < 0) {
        warn("open <stdin> failed: %e.\n", fd);
    }
    if ((fd = initfd(1, "stdout:", O_WRONLY)) < 0) {
        warn("open <stdout> failed: %e.\n", fd);
    }
    int ret = main(argc, argv); // 调用实际的main函数
    exit(ret); // 退出程序，返回main函数的返回值
}

/*
argc, argv: 主函数的参数，分别表示参数数量和参数列表。
initfd 用于确保标准输入和标准输出分别被分配到文件描述符 0 和 1。
*/
