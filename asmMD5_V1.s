section .bss
    block resb 64   ; Réserver 64 octets pour le bloc de données
    state resd 4    ; Réserver 4 mots (32 bits chacun) pour l'état
    message resb 128 ; Réserver 128 octets pour le message (vous pouvez ajuster la taille)
    result resb 33   ; Réserver 33 octets pour le résultat (32 caractères hex + '\0')

section .text
global _start
global md5_compress

_start:
    ; Initialiser le message (exemple: "abc")
    mov r15, message
    mov byte [r15], 'a'
    mov byte [r15+1], 'b'
    mov byte [r15+2], 'c'
    mov byte [r15+3], 0

    ; Initialiser l'état
    mov dword [state], 0x67452301
    mov dword [state+4], 0xefcdab89
    mov dword [state+8], 0x98badcfe
    mov dword [state+12], 0x10325476

    ; Calculer le hachage
    mov rdi, r15
    mov rsi, 3
    mov rdx, state
    call md5_hash

    ; Convertir l'état en une chaîne hexadécimale
    mov rdi, state
    mov rsi, result
    call to_hex_string

    ; Afficher le résultat
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, 32
    syscall
    
    ; Sortir du programme
    mov rax, 60
    xor rdi, rdi
    syscall

md5_hash:
    ; Entrées:
    ; rdi - adresse du message
    ; rsi - longueur du message
    ; rdx - adresse de l'état
    ; Réserver l'espace pour le bloc
    push rbx
    push rbp

    ; Initialiser les variables locales
    sub rsp, 64  ; Réserver l'espace pour le bloc
    mov rbp, rsp ; Adresse du bloc local
    xor rbx, rbx ; Initialiser rbx à 0

    ; Copie du message dans le bloc
    mov rcx, rsi
    mov rsi, rdi
    mov rdi, rbp
    rep movsb

    ; Padding du bloc
    mov byte [rbp+rcx], 0x80
    inc rcx
    xor rax, rax
    lea rdi, [rbp+rcx]
    mov rsi, 56
    sub rsi, rcx
    rep stosb

    ; Ajouter la longueur du message en bits
    mov rax, rsi
    shl rax, 3
    mov [rbp+56], rax

    ; Appeler md5_compress pour le bloc
    mov rdi, rbp
    mov rsi, rdx
    call md5_compress

    ; Restaurer la pile et retourner
    add rsp, 64
    pop rbp
    pop rbx
    ret

md5_compress:
    ; Sauvegarder les registres
    push rbx
    push rbp

    ; Charger les arguments
    mov rbp, rdi
    mov r8, rsi

    ; Charger l'état initial dans les registres
    mov eax, dword [r8]       ; a
    mov ebx, dword [r8+4]     ; b
    mov ecx, dword [r8+8]     ; c
    mov edx, dword [r8+12]    ; d

    ; Les macros pour les rounds
    %macro ROUND0 7
        mov esi, %3
        add esi, dword [%5*4 + rbp]
        xor esi, %4
        and esi, %2
        xor esi, %4
        add esi, %1
        rol esi, %6
        add esi, %2
        mov %1, esi
    %endmacro

    %macro ROUND1 7
        mov esi, %4
        mov edi, %4
        add esi, dword [%5*4 + rbp]
        not esi
        and edi, %2
        and esi, %3
        or edi, esi
        add edi, %1
        rol edi, %6
        add edi, %2
        mov %1, edi
    %endmacro

    %macro ROUND2 7
        mov esi, %3
        add esi, dword [%5*4 + rbp]
        xor esi, %4
        xor esi, %2
        add esi, %1
        rol esi, %6
        add esi, %2
        mov %1, esi
    %endmacro

    %macro ROUND3 7
        mov esi, %4
        not esi
        add esi, dword [%5*4 + rbp]
        or esi, %2
        xor esi, %3
        add esi, %1
        rol esi, %6
        add esi, %2
        mov %1, esi
    %endmacro

    ; Les 64 tours de hachage
    ROUND0 eax, ebx, ecx, edx, 0, 7, 0xd76aa478
    ROUND0 edx, eax, ebx, ecx, 1, 12, 0xe8c7b756
    ROUND0 ecx, edx, eax, ebx, 2, 17, 0x242070db
    ROUND0 ebx, ecx, edx, eax, 3, 22, 0xc1bdceee
    ROUND0 eax, ebx, ecx, edx, 4, 7, 0xf57c0faf
    ROUND0 edx, eax, ebx, ecx, 5, 12, 0x4787c62a
    ROUND0 ecx, edx, eax, ebx, 6, 17, 0xa8304613
    ROUND0 ebx, ecx, edx, eax, 7, 22, 0xfd469501
    ROUND0 eax, ebx, ecx, edx, 8, 7, 0x698098d8
    ROUND0 edx, eax, ebx, ecx, 9, 12, 0x8b44f7af
    ROUND0 ecx, edx, eax, ebx, 10, 17, 0xffff5bb1
    ROUND0 ebx, ecx, edx, eax, 11, 22, 0x895cd7be
    ROUND0 eax, ebx, ecx, edx, 12, 7, 0x6b901122
    ROUND0 edx, eax, ebx, ecx, 13, 12, 0xfd987193
    ROUND0 ecx, edx, eax, ebx, 14, 17, 0xa679438e
    ROUND0 ebx, ecx, edx, eax, 15, 22, 0x49b40821

    ROUND1 eax, ebx, ecx, edx, 1, 5, 0xf61e2562
    ROUND1 edx, eax, ebx, ecx, 6, 9, 0xc040b340
    ROUND1 ecx, edx, eax, ebx, 11, 14, 0x265e5a51
    ROUND1 ebx, ecx, edx, eax, 0, 20, 0xe9b6c7aa
    ROUND1 eax, ebx, ecx, edx, 5, 5, 0xd62f105d
    ROUND1 edx, eax, ebx, ecx, 10, 9, 0x02441453
    ROUND1 ecx, edx, eax, ebx, 15, 14, 0xd8a1e681
    ROUND1 ebx, ecx, edx, eax, 4, 20, 0xe7d3fbc8
    ROUND1 eax, ebx, ecx, edx, 9, 5, 0x21e1cde6
    ROUND1 edx, eax, ebx, ecx, 14, 9, 0xc33707d6
    ROUND1 ecx, edx, eax, ebx, 3, 14, 0xf4d50d87
    ROUND1 ebx, ecx, edx, eax, 8, 20, 0x455a14ed
    ROUND1 eax, ebx, ecx, edx, 13, 5, 0xa9e3e905
    ROUND1 edx, eax, ebx, ecx, 2, 9, 0xfcefa3f8
    ROUND1 ecx, edx, eax, ebx, 7, 14, 0x676f02d9
    ROUND1 ebx, ecx, edx, eax, 12, 20, 0x8d2a4c8a

    ROUND2 eax, ebx, ecx, edx, 5, 4, 0xfffa3942
    ROUND2 edx, eax, ebx, ecx, 8, 11, 0x8771f681
    ROUND2 ecx, edx, eax, ebx, 11, 16, 0x6d9d6122
    ROUND2 ebx, ecx, edx, eax, 14, 23, 0xfde5380c
    ROUND2 eax, ebx, ecx, edx, 1, 4, 0xa4beea44
    ROUND2 edx, eax, ebx, ecx, 4, 11, 0x4bdecfa9
    ROUND2 ecx, edx, eax, ebx, 7, 16, 0xf6bb4b60
    ROUND2 ebx, ecx, edx, eax, 10, 23, 0xbebfbc70
    ROUND2 eax, ebx, ecx, edx, 13, 4, 0x289b7ec6
    ROUND2 edx, eax, ebx, ecx, 0, 11, 0xeaa127fa
    ROUND2 ecx, edx, eax, ebx, 3, 16, 0xd4ef3085
    ROUND2 ebx, ecx, edx, eax, 6, 23, 0x04881d05
    ROUND2 eax, ebx, ecx, edx, 9, 4, 0xd9d4d039
    ROUND2 edx, eax, ebx, ecx, 12, 11, 0xe6db99e5
    ROUND2 ecx, edx, eax, ebx, 15, 16, 0x1fa27cf8
    ROUND2 ebx, ecx, edx, eax, 2, 23, 0xc4ac5665

    ROUND3 eax, ebx, ecx, edx, 0, 6, 0xf4292244
    ROUND3 edx, eax, ebx, ecx, 7, 10, 0x432aff97
    ROUND3 ecx, edx, eax, ebx, 14, 15, 0xab9423a7
    ROUND3 ebx, ecx, edx, eax, 5, 21, 0xfc93a039
    ROUND3 eax, ebx, ecx, edx, 12, 6, 0x655b59c3
    ROUND3 edx, eax, ebx, ecx, 3, 10, 0x8f0ccc92
    ROUND3 ecx, edx, eax, ebx, 10, 15, 0xffeff47d
    ROUND3 ebx, ecx, edx, eax, 1, 21, 0x85845dd1
    ROUND3 eax, ebx, ecx, edx, 8, 6, 0x6fa87e4f
    ROUND3 edx, eax, ebx, ecx, 15, 10, 0xfe2ce6e0
    ROUND3 ecx, edx, eax, ebx, 6, 15, 0xa3014314
    ROUND3 ebx, ecx, edx, eax, 13, 21, 0x4e0811a1
    ROUND3 eax, ebx, ecx, edx, 4, 6, 0xf7537e82
    ROUND3 edx, eax, ebx, ecx, 11, 10, 0xbd3af235
    ROUND3 ecx, edx, eax, ebx, 2, 15, 0x2ad7d2bb
    ROUND3 ebx, ecx, edx, eax, 9, 21, 0xeb86d391

    ; Mettre à jour l'état avec les résultats
    add dword [r8], eax
    add dword [r8+4], ebx
    add dword [r8+8], ecx
    add dword [r8+12], edx

    ; Restaurer les registres et retourner
    pop rbp
    pop rbx
    ret

to_hex_string:
    ; rdi - adresse de l'état
    ; rsi - adresse de la chaîne résultat
    mov rcx, 16
    xor rbx, rbx

to_hex_loop:
    mov al, [rdi+rbx]
    mov ah, al
    shr al, 4
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jle .skip_adjust
    add al, 7
.skip_adjust:
    mov [rsi+rbx*2], al

    mov al, ah
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jle .skip_adjust2
    add al, 7
.skip_adjust2:
    mov [rsi+rbx*2+1], al

    inc rbx
    loop to_hex_loop

    mov byte [rsi+32], 0
    ret
