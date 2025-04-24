# 🧮 MIPS Assembly: Linear Equation Solver using Cramer’s Rule

## 📌 Project Description

This project implements a linear equation solver based on **Cramer’s Rule**, developed in **MIPS assembly language**. The application reads systems of equations from a text file, processes them into matrix format, computes solutions using determinant calculations, and outputs results either to the screen or to a file.

---

## 🛠 Features

### 📖 1. File Input Handling

- The user is prompted to enter the name of a text file containing multiple systems of linear equations.
- Equations are separated by empty lines and processed sequentially.
- Each equation is stored in memory and prepared for parsing and matrix transformation.

### 🔍 2. Equation Parsing and Matrix Formation

- Each line is parsed to extract the coefficients of variables (x, y, z) and constants.
- The equations are then transformed into:
  - A **coefficient matrix**.
  - A **result/output matrix**.

#### ✏️ Example Input

```
2x + 3y = 5  
4x - y = 1
```

#### ➗ Becomes

```
| 2  3 |   | x |   =   | 5 |
| 4 -1 |   | y |       | 1 |
```

---

### ➗ 3. Solving with Cramer’s Rule

- The program calculates the main determinant (**D**) from the coefficient matrix.
- It then computes **Dx**, **Dy**, and **Dz** by replacing the corresponding column with the constants matrix.
- The solution is calculated as:

```
X = Dx / D
Y = Dy / D
Z = Dz / D
```

#### 🧮 Determinants:

- **2×2 systems**: Solved using simple cross-multiplication.
- **3×3 systems**: Solved using Laplace expansion.

---

### 💬 4. Output Options

After processing a system, users can choose how to view the results:

- **S**/**s**: Print the solution on the screen.
- **F**/**f**: Save the results to a text file.
- The output is clearly formatted, showing the system matrix and solution.

---

### ⚠️ 5. Error Detection and Handling

- The program verifies:
  - Valid equation formats.
  - Consistency between number of variables and equations.
  - Non-zero determinant (i.e., system is solvable).
- If errors occur (e.g., division by zero, invalid input, malformed lines), the program notifies the user and allows retry.

---

### 🔁 6. Continuous Operation

- After processing each system, the program loops and prompts for a new file.
- Users can exit by entering **e** or **E**.

---

## 📝 Sample Input File (`test.txt`)

```
-x + y + z = 0
x + y = 9
z = 8

3x + 2y + z = 0
x + y = 9
z = 8

5x - 2y + z = 0
x - y = 9
z = 3

-6x + y = 12
x + 2y = 9

-12x + y = 24
4y = 9

-x + y = 0
x + y = 9

x - y = 0
x + y = 9

x + y = 1
y = 9

x + y = 9

12x - 10y = 46
3x + 20y = -11

3x - 4y + 8z = 34
4x + y - 2z = 1
-6x - 13y + 20z = 61
```

---

## 💡 Example Output

### System:

```
-x + y + z = 0
x + y = 9
z = 8
```

### Matrices:

```
Coefficient Matrix:
-1   1   1  
 1   1   0  
 0   0   1  

Output Matrix:
 0  
 9  
 8  
```

### Solution:

```
X = -17 / -2
Y = -1 / -2
Z = -16 / -2
```

### Other Results (simplified):

```
X = -26 / 1   |   Y = 35 / 1   |   Z = 8 / 1  
X = 21 / -3   |   Y = 48 / -3  |   Z = -9 / -3  
X = 15 / -13  |   Y = -66 / -13  
...
```

---

## 💾 Output Options

```
Options:
[S/s] Print results on screen
[F/f] Save results to file
[E/e] Exit the program
```

---

## ✅ Program Flow Summary

```
START
↓
Prompt for file input
↓
Read & parse equations
↓
Check system validity
↓
Solve using Cramer's Rule
↓
Display or Save output
↓
Repeat or Exit
```

---

## 📂 Usage

Run the program in a MIPS simulator (like [MARS](https://courses.missouristate.edu/KenVollmar/MARS/) or [QtSPIM](http://spimsimulator.sourceforge.net/)):

```
> Enter the file name or E to exit: test.txt
> Choose Output Option: s (or f/e)
```

---

## 📎 Notes

- Handles both 2-variable and 3-variable systems.
- Handles multiple equation systems per input file.
- Solutions are kept in fractional form (not simplified).
- Singular matrices (determinant = 0) are flagged as unsolvable.


## © License

This project is open-source and freely available under the MIT License.

---
