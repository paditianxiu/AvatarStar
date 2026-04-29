/**
 * Frida Agent 脚本 for AvatarStar.exe 协议分析 (最终稳定版 - 移除IP重定向)
 * 目的: 专注于捕获客户端发送和接收的协议数据包。
 * * 核心Hook地址:
 * - Send Wrapper: 0x429E90
 * - Recv Wrapper: 0x45BB8B (已修复缓冲区访问问题)
 */

// --- Hook 地址 ---
// 🚨 注意：请确认您已通过配置文件设置了私服IP，这些地址用于捕获数据包
const SEND_WRAPPER_ADDR    = 0x429E90; // 发送封装函数地址 (用于数据包捕获)
const RECV_WRAPPER_ADDR    = 0x45BB8B; // 接收封装函数地址 (用于数据包捕获)


// --- 辅助函数：安全 Hook ---

/**
 * 尝试安全地 Hook 一个地址。如果失败，将捕获错误。
 */
function safeHook(targetAddress: NativePointer, hookName: string, callbacks: any) {
    try {
        Interceptor.attach(targetAddress, callbacks);
        console.log(`[+] 成功 Hook ${hookName} (${targetAddress})`);
    } catch (e) {
        console.log(`[-] 错误：无法 Hook ${hookName} (${targetAddress})。详细信息: ${e}`);
    }
}


// --- 主要 Agent 逻辑 ---

try {
    const baseAddress = Module.getBaseAddress('AvatarStar.exe');
    console.log(`[INFO] AvatarStar.exe 模块基址: ${baseAddress}`);
} catch (e) {
    console.log(`[ERROR] 无法获取 AvatarStar.exe 基址。`);
}


// ====================================================================
// 1. 发送数据 Hook (0x429E90) - 捕获客户端发出的数据包
// ====================================================================

safeHook(ptr(SEND_WRAPPER_ADDR), 'Network Send Wrapper', {
    onEnter: function(args) {
        // 假设 buf = args[2], len = args[3]
        const pBuffer = args[2]; 
        const pSize = args[3].toInt32(); 

        console.log(`\n>>> SEND Buffer [0x${SEND_WRAPPER_ADDR.toString(16)}] - Size: ${pSize}`);

        if (pSize > 0) {
            try { 
                // 打印发送的数据包，分析操作码和结构
                console.log(hexdump(pBuffer, { length: pSize }));
            } catch (error) {
                // 如果 pBuffer 无效，打印错误但不崩溃
                console.log(`Error dumping SEND buffer: ${error}`);
            }
        }
    }
});


// ====================================================================
// 2. 接收数据 Hook (0x45BB8B) - 捕获服务器返回的数据包 (修复缓冲区访问)
// ====================================================================

safeHook(ptr(RECV_WRAPPER_ADDR), 'Network Recv Wrapper (FIXED)', {
    onEnter: function(args) {
        // 假设 args[1] = buf, args[2] = len
        const pSize = args[2].toInt32();
        
        // 🚨 缓冲区指针修复：从堆栈中读取 buf 参数 (通常在 esp+12)
        // 这是为了解决 'access violation accessing 0x2000' 错误
        const pBufferStack = this.context.sp.add(12).readPointer();
        
        if (pBufferStack.toInt32() > 0x10000) {
            // 如果堆栈读取到的指针看起来有效，我们信任它
            this.pBuffer = pBufferStack;
        } else {
            // 否则，使用 Frida 自动识别的参数 (args[1]) 作为备份，但风险更高
            this.pBuffer = args[1]; 
        }
        
        this.pSize = pSize; 
        console.log(`\n<<< RECV Wrapper (FIXED) [0x${RECV_WRAPPER_ADDR.toString(16)}] - Requested Size: ${this.pSize}`);
    },
    onLeave: function(retval) {
        const actualSize = retval.toInt32();
        
        // 只有当实际有数据，并且缓冲区指针看起来有效时才尝试读取
        if (actualSize > 0 && this.pBuffer.toInt32() > 0x10000) {
            console.log(`<<< RECV Data - Actual Size: ${actualSize}`);
            try {
                // 读取实际接收到的数据
                console.log(hexdump(this.pBuffer, { length: actualSize }));
            } catch (error) {
                console.log(`Error dumping RECV buffer: ${error}`);
            }
        } else if (actualSize > 0) {
            console.log(`<<< RECV Data - Actual Size: ${actualSize}. Buffer pointer was bad, skipping hexdump.`);
        }
    }
});