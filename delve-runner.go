package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

func main() {
	var err error
	var lc io.Closer

	if lc, err = initLog(); err != nil {
		log.Fatal(err)
	}
	defer lc.Close()

	fmt.Println("message: starting dlv")

	cmd := exec.Command("dlv", "--init", "init.txt", "--allow-non-terminal-interactive", "connect", "127.0.0.1:8077")

	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Fatal(err)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}

	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}

	in := bufio.NewReader(os.Stdin)
	out := bufio.NewReader(stdout)

	var dcommand string

	fmt.Println("message: delve started")

	go func() {
		for {
			s, err := out.ReadString('\n')
			if err != nil {
				break
			}

			if strings.Contains(s, "PC: ") {
				cc := strings.Split(s, " ")
				for _, ss := range cc {
					if strings.Contains(ss, ".go:") {
						fmt.Println("command: open", ss)
					}
				}
			} else {
				if dcommand != "n" && dcommand != "so" && dcommand != "s" {
					s = strings.ReplaceAll(s, "(dlv) ", "")
					log.Print(s)
				}
			}
		}
	}()

	for {
		dcommand, err = in.ReadString('\n')
		if err != nil {
			log.Println(err)
			break
		}
		dcommand = strings.TrimSpace(dcommand)
		_, err = stdin.Write([]byte(dcommand + "\n"))
		log.Println("command:", dcommand)
		if dcommand == "q" {
			log.Println("quit")
			break
		}
		if err != nil {
			log.Println(err)
			break
		}
	}

	if err := cmd.Wait(); err != nil {
		log.Fatal(err)
	}
}

func initLog() (io.Closer, error) {
	log.SetFlags(0)

	lf, err := os.Create("/tmp/delve-runner.log")
	if err != nil {
		return nil, err
	}

	log.SetOutput(lf)

	return lf, nil
}
