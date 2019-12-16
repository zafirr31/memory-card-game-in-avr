# Game tebak kartu di AVR

Repo ini digunakan untuk mendokumentasi progress proyek akhir matkul Pengantar Organisasi Komputer

Spesifikasi:
- Atmega8515
- 4.0 Mhz Clock

Kolaborator (Random Algorithm):
- Sean Zeliq Urian
- Adrian Wijaya
- Falih Mufazan<br>
Kelas POK-B


Petunjuk Penggunaan:

Pada saat game ini dijalankan, akan muncul LCD yang berperan sebagai layar, keypad untuk memainkannya, LED yang berfungsi sebagai penunjuk apakah kartu yang kita buka benar atau tidak dan button yang memiliki tombol reset untuk merestart game. Pada saat pertama kali game ini akan meminta input berupa nama. Input ini dilakukan huruf per huruf dan tiap kali memasukkan huruf kita bisa menekan Up pada keypad untuk menaikkan hurufnya atau Down untuk menurunkan hurufnya.

Setelah itu, ketika ingin berpindah satu digit ke kanan, kita bisa menekan Enter. Setelah kita memasukkan nama, selanjutnya layar akan menampilkan hasil random berupa kartu - kartu yang belum terbuka. Kita dapat menggunakan keypad untuk menggerakkan cursor. Ketika kita ingin membuka kartu di suatu posisi, maka kita dapat menekan Enter setelah cursornya berada pada kartu tersebut dan led kuning akan menyala. Jika kita membuka 2 kartu yang berbeda maka LED merah akan menyala disertai dengan kedua kartu tersebut akan tertutup kembali dan sebaliknya jika kita membuka 2 kartu yang sama maka LED hijau akan menyala disertai kedua kartu tersebut akan terus terbuka hingga game berakhir.

Game ini akan berakhir jika kita berhasil membuka semua kartu. Setelah game ini berakhir, layar akan menampilkan score kita dan setelah itu menampilkan pula highscore sementara.