// ========================================================================
// AvatarStar 全网罗网监控 V51 (TCP + UDP + HTTP + New Send Hook)
// ========================================================================

const SEND_WRAPPER_ADDR = 0x429E90; 
const SEND_3BYTE_ADDR   = 0x432CD0; 
const SEND_LOGIC_3_ADDR = 0x433720; 
const SEND_MEMBER_ADDR  = 0x45BBA3; // 新增：成员函数发送 (0x45BBA3)

const RECV_WRAPPER_1_ADDR = 0x429F60; 
const RECV_WRAPPER_2_ADDR = 0x42B4C0; 
const RECV_WRAPPER_3_ADDR = 0x45BB8B; 
const RECV_LOOP_ADDR      = 0x430840; 

const ws2 = "ws2_32.dll";
const wininet = "wininet.dll";

Process.setExceptionHandler(function(details) { return false; });

function safeHook(targetAddress, hookName, callbacks) {
    if (targetAddress.isNull()) return;
    try {
        Interceptor.attach(targetAddress, callbacks);
        console.log(`[+] 成功 Hook ${hookName} (${targetAddress})`);
    } catch (e) {
        console.log(`[-] Hook 失败: ${hookName} - ${e.message}`);
    }
}

console.log("=== AvatarStar Protocol Monitor V51 ===");

// 0. Load Modules
try { Module.load(wininet); } catch(e) {}
try { Module.load(ws2); } catch(e) {}

// 1. Internal Receive Hooks
safeHook(ptr(RECV_WRAPPER_1_ADDR), 'Game_Recv_1(0x429F60)', {
    onEnter: function(args) { this.buf = args[2]; try { this.len = args[3].toInt32(); } catch(e) { this.len = 0; } },
    onLeave: function(retval) {
        try {
            let len = retval.toInt32();
            if (len <= 0) len = this.len;
            if (len > 0 && len < 65536 && !this.buf.isNull()) {
                console.log(`\n<<< GAME_RECV_1 (XML?) Size: ${len}`);
                console.log(hexdump(this.buf, { length: len, header: false, ansi: true }));
            }
        } catch(e) {}
    }
});

safeHook(ptr(RECV_WRAPPER_2_ADDR), 'Game_Recv_2(0x42B4C0)', {
    onEnter: function(args) { this.buf = args[0]; try { this.len = args[1].toInt32(); } catch(e) { this.len = 0; } },
    onLeave: function(retval) {
        try {
            let len = retval.toInt32();
            if (len <= 0) len = this.len;
            if (len > 0 && len < 65536 && !this.buf.isNull()) {
                console.log(`\n<<< GAME_RECV_2 (Config?) Size: ${len}`);
                console.log(hexdump(this.buf, { length: len, header: false, ansi: true }));
            }
        } catch(e) {}
    }
});

safeHook(ptr(RECV_WRAPPER_3_ADDR), 'Game_Recv_3(0x45BB8B)', {
    onEnter: function(args) { this.buf = args[0]; try { this.len = args[1].toInt32(); } catch(e) { this.len = 0; } },
    onLeave: function(retval) {
        try {
            let len = retval.toInt32();
            if (len <= 0) len = this.len;
            if (len > 0 && len < 65536 && !this.buf.isNull()) {
                console.log(`\n<<< GAME_RECV_3 (Login/Lobby) Size: ${len}`);
                console.log(hexdump(this.buf, { length: len, header: false, ansi: true }));
            }
        } catch(e) {}
    }
});

// 2. WinINet (HTTPS)
const sysHttpSendRequestW = Module.findExportByName(wininet, "HttpSendRequestW");
if (sysHttpSendRequestW) {
    Interceptor.attach(sysHttpSendRequestW, {
        onEnter: function(args) {
            try {
                const lpOptional = args[3];
                const dwLen = args[4].toInt32();
                if (dwLen > 0 && !lpOptional.isNull()) {
                    console.log(`\n>>> HTTPS SEND (POST) Size: ${dwLen}`);
                    console.log(hexdump(lpOptional, { length: dwLen, header: false, ansi: true }));
                }
            } catch (e) {}
        }
    });
}

// 3. Internal Send Hooks
safeHook(ptr(SEND_WRAPPER_ADDR), 'Game_Send_Gen(0x429E90)', {
    onEnter: function(args) {
        try {
            const pBuffer = args[2]; 
            const pSize = args[3].toInt32(); 
            if (pSize > 0 && pSize < 10000) {
                console.log(`\n>>> GAME_SEND_TCP (0x429E90) Size: ${pSize}`);
                console.log(hexdump(pBuffer, { length: pSize, header: false, ansi: true })); 
            }
        } catch (e) { }
    }
});

safeHook(ptr(SEND_3BYTE_ADDR), 'Game_Send_3B(0x432CD0)', {
    onEnter: function(args) {
        try {
            const byte2 = args[0].toInt32() & 0xFF;
            console.log(`\n>>> GAME_SEND_3B (0x432CD0) Size: 3`);
            console.log(`FF ${byte2.toString(16).padStart(2, '0')} ??`); 
        } catch (e) { }
    }
});

// 新增: Member Send Hook
safeHook(ptr(SEND_MEMBER_ADDR), 'Game_Send_Member(0x45BBA3)', {
    onEnter: function(args) {
        try {
            // __thiscall: args[0]=buf, args[1]=len, args[2]=flags
            const pBuffer = args[0];
            const pSize = args[1].toInt32();
            if (pSize > 0 && pSize < 10000 && !pBuffer.isNull()) {
                console.log(`\n>>> GAME_SEND_MEMBER (0x45BBA3) Size: ${pSize}`);
                console.log(hexdump(pBuffer, { length: pSize, header: false, ansi: true }));
            }
        } catch (e) { }
    }
});

// 4. System Socket Hooks (TCP & UDP)

const sysSend = Module.findExportByName(ws2, "send");
if (sysSend) {
    Interceptor.attach(sysSend, {
        onEnter: function(args) {
            this.buf = args[1];
            try { this.len = args[2].toInt32(); } catch(e) { this.len = 0; }
        },
        onLeave: function(retval) {
            try {
                const sent = retval.toInt32();
                if (sent > 0 && !this.buf.isNull()) {
                    console.log(`\n>>> SYS_SEND (TCP) Size: ${sent}`);
                    console.log(hexdump(this.buf, { length: sent, header: false, ansi: true }));
                }
            } catch (e) {}
        }
    });
    console.log(`[+] 成功 Hook send (TCP)`);
}

// 🚨 Hook UDP sendto
const sysSendTo = Module.findExportByName(ws2, "sendto");
if (sysSendTo) {
    Interceptor.attach(sysSendTo, {
        onEnter: function(args) {
            this.buf = args[1];
            try { this.len = args[2].toInt32(); } catch(e) { this.len = 0; }
            this.to = args[4]; // 目标地址结构体
        },
        onLeave: function(retval) {
            try {
                const sent = retval.toInt32();
                if (sent > 0 && !this.buf.isNull()) {
                    console.log(`\n>>> SYS_SENDTO (UDP) Size: ${sent}`);
                    if (!this.to.isNull()) {
                         const port = this.to.add(2).readU16(); 
                         const portLE = ((port & 0xFF) << 8) | ((port >> 8) & 0xFF);
                         console.log(`    Target Port: ${portLE}`);
                    }
                    console.log(hexdump(this.buf, { length: sent, header: false, ansi: true }));
                }
            } catch (e) {}
        }
    });
    console.log(`[+] 成功 Hook sendto (UDP)`);
}