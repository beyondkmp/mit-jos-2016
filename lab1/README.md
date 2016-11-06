# lab1

## Part1: PC Bootstrap

### The PC's Physical Address Space

```

+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```

最早的PC机,是基于16位的intel的8086处理器,最多只能访问1M的物理内容.早期的PC机的物理寻址范围是:` 0x00000000 ~ 0x000FFFFF`. 在上图中的640KB以下的区域被标记为"Low Memory",早期计算机只能使用这个区域内的内存.

剩下的384KB区域( 0x000A0000 到 0x000FFFFF)是保留给硬件特殊使用的,比如用做video display  buggers和 firmware held in non-volatile memory.

最重要的是保留区域是Basic Input/Output System(BIOS),总共拥有64KB大小,范围从0x000F0000 到 0x000FFFFF.早期电脑的BIOS存储在ROM,现在的BIOS存储在updateable flash memory.BIOS的主要作用是基本系统的初始化,例如激活显卡,检测内存大小.在初始化完成后,BIOS会从适当的引导盘(floppy disk,hard disk,CD0ROM 或者网络)加载操作系统,加载完后将控制权交给操作系统.



