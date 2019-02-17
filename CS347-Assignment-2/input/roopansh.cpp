/************************
ROOPANSH BANSAL
150101053
CS210
************************/

#include <bits/stdc++.h>

using namespace std;

// Structure of a node
struct Node
{
    Node *Down , *Right ;//  pointers to the nodes down of this node and right of this node 
    int row , col  ,val;//  Stores the row & column number of the node and the value to be stored in that position 
};

// SparseMatrix class to implement the Sparse matrix 
class SparseMatrix
{
private:
	Node Root;// stores the number of rows , columns , elements in the matrix
	Node **Heads;// pointer to an array of Nodes pointers which points to the Heads(i.e. the starting of rows and cols)
public:
	SparseMatrix(int row , int col , int elements); // Constructor
	Node *CreateNode(int row , int col , int val); // Create a node with the given arguments as its properties
	void BuildMatrix(); // build the matrix using random positions and random values
	bool InsertNode(Node *NodeToInsert); // Insert the node to the matrix
	int RandomRow(); // returns a random value of the possible row number 
	int RandomCol(); // returns a random value of the possible column number
	int RandomVal(); // returns a random number for the value ot be stored
	Node * HighsetValue(); // returns a pointer to the node which has highest value
};

int main()
{
	//Seed the random fucntion
	srand(time(NULL));

	// input the following properties from the user
    int row , col , elements;
    cout<<"Enter the number of Rows:\t";
    cin>>row;
    cout<<"Enter the number of Columns:\t";
    cin>>col;
    cout<<"Enter the number of Elements:\t";
    cin>>elements;

    // if the number of elements input by user are greater than the capacity of the sparse matrix , quit the program with an error
    if (elements > row*col)
    {
    	cout<<"ERROR OVERFLOW : Number of elements entered is more than the size of the sparse matrix."<<endl;
    	return 0;
    }
    if (elements < 0)
    {
    	cout<<"ERROR : Please enter valid number of elements."<<endl;
    	return 0;
    }

    // Declare a empty sparse matrix
    SparseMatrix SM(row ,col ,elements);
    // cout<<"Sparse Matrix Constructor Run Successfully"<<endl;

    //Construct a sparse matrix with k random values inserted at k random positions in the sparse matrix
    SM.BuildMatrix();
    // cout<<"Sparse Matrix Built Successfully"<<endl;

    // find the node with the highest value
    Node * HightestValNode = SM.HighsetValue();
    if (HightestValNode == NULL)
    {
    	cout<<"Sparse Matrix is empty."<<endl;
    	cout<<"Hence there is no highest value."<<endl;
    }
    else
    {
	    cout<<"Highest value in the sparse matrix is:\t"<<HightestValNode->val<<endl;
	}
    return 0;
}

//Constructor of the SparseMatrix Class
SparseMatrix::SparseMatrix(int row , int col , int elements)
{
	//Root of the sparse matrix stores the number of rows , columns and the number of elements in the matrix.
	Root.row = row;
	Root.col = col;
	Root.val = elements;

	// number of headers to make is the maximum of the number of the rows and columns
	int n = max(row , col);
	Heads = new Node*[n+1];

	// allocate memory for each head
	for (int i = 1; i <= n; ++i)
	{
		Heads[i] = new Node;
	}

	// Root points to the first head of the row and column
	Root.Down = Heads[1];
	Root.Right = Heads[1];

	//Set the different properties and values of the different heads
	int i;
	for (i = 1; i <= n; ++i)
	{
		//Initially the head points to themselves like a circular queue
		Heads[i]->Down = Heads[i];
		Heads[i]->Right = Heads[i];

		//we store 0 in the row,col,val of the headers....they denote nothing...just some value
		// these value helps when finding the correct poistion for the new node to store(check the insert node funciton for better understanding)
		Heads[i]->row = 0;
		Heads[i]->col = 0;
		Heads[i]->val = 0;
	}
}

// Create a node with the given arguments as its properties
Node* SparseMatrix::CreateNode(int row , int col , int val)
{
	// allocate memory for the new node
	Node * temp = new Node;
	//update it's values
	temp->row = row;
	temp->col = col;
	temp->val = val;
	return temp ;
}

// build the matrix using random positions and random values
void SparseMatrix::BuildMatrix()
{
	// counter is to count the number of elements stroed in the sparse matrix
	int Counter = 0;

	// maximum number of elements to be stored in the matrix is given by the user
	while(Counter < Root.val)
	{
		// random row number , column number , value to be stored in that position
		int i , j , val;
		i = RandomRow();
		j = RandomCol();
		val = RandomVal();

		// create a node with that properties
		Node *temp = CreateNode(i , j , val);
		
		// insert it in the sparse matrix
		if(InsertNode(temp))
		{
			Counter++;
		}
		else// it returns false if that posiiton is already occupied.(BCZ of random function.)
		{
			delete(temp);// free that memory
		}
	}
}

// Insert the node to the matrix
bool SparseMatrix::InsertNode(Node *NodeToInsert)
{
	int row = NodeToInsert->row;// the row to insert the node to
	int col = NodeToInsert->col;// the column to insert the node to

	// first updating the matrix the column
	Node * ColPtr1 = Heads[col];
	Node * ColPtr2 = ColPtr1->Down;
	// traverse the column once to find the correct position
	while(ColPtr2 != Heads[col] && ColPtr1->row < row)
	{
		ColPtr1 = ColPtr2;
		ColPtr2 = ColPtr2->Down;
	}
	if (ColPtr1->row == row)// if that position is already occupied , return false
	{
		return false;
	}

	// now updating the sparse matrix along the rows
	Node * RowPtr1 = Heads[row];
	Node * RowPtr2 = RowPtr1->Right;
	// traverse the row once to find the correct position
	while(RowPtr2 != Heads[row] && RowPtr1->col < col)
	{
		RowPtr1 = RowPtr2;
		RowPtr2 = RowPtr2->Right;
	}
	if (RowPtr1->col == col)// if that position is already occupied , return false
	{
		return false;
	}

	// Update the down and right pointers of the required nodes
	// (i.e. add the required node to it's required position). 
	ColPtr1->Down = NodeToInsert;
	NodeToInsert->Down = ColPtr2;	
	RowPtr1->Right = NodeToInsert;
	NodeToInsert->Right = RowPtr2;
	//return true to denote that node is inserted in its correct position
	return true;
}

// random valid row number
int SparseMatrix::RandomRow()
{
	return rand()%Root.row +1;
}
// random valid column number
int SparseMatrix::RandomCol()
{
	return rand()%Root.col +1;
}
// random value
int SparseMatrix::RandomVal()
{
	return rand()%1000000 +1;
}

// to find th enode witht he highest value
Node * SparseMatrix::HighsetValue()
{
	static int count = 1;
	int max = INT_MIN;// initialise the highest value to INF_MIN
	Node * HightestValNode = NULL;
	for (int i = 1; i <= Root.row; ++i)// find along the rows starting from the first row
	{
		//traverse along each row once to update the highest value node.
		Node * NodePtr = Heads[i]->Right;
		while(NodePtr != Heads[i])
		{
			if (NodePtr->val > max)
			{
				max = NodePtr->val;
				HightestValNode = NodePtr;
			}
			cout<<count++<<"\t"<<NodePtr->val<<endl;
			NodePtr = NodePtr->Right;
		}
	}
	return HightestValNode;
}