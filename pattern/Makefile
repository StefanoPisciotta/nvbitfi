TARGET = app_name

# CUDA
NVCC = `which nvcc`
ARCH=35

all: clean $(TARGET) 

$(TARGET): 
	$(NVCC) -o app_name -Xptxas -v -arch=sm_$(ARCH) app_name.cu 

test:
	./app_name 

golden:
	./app_name >golden_stdout.txt 2>golden_stderr.txt

clean:
	rm -f *.o *~ app_name

clobber: clean
	rm -f golden* *_regcount.p stdout* stderr*
