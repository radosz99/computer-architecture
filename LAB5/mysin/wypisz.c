#include <stdio.h>

float mysin(float);

int main(){
   	float data, result;

    printf("Program za pomocą funkcji asemblerowej liczy sinus z kąta danego w radianach\n\nPODAJ LICZBĘ: ");
    scanf("%f", &data);
 
    result = mysin(data);
    printf("\nsin(%f) = %f\n", data, result);

return 0;
}


