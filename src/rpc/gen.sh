#! /bin/sh
# Copyright (C) Tao Ma(tao.ma.1984@gmail.com)

pkgname=rpc
outfile=pbpayload.go
protofile=msg.proto

echo "generate new protobuf file..."
protoc --go_out=. "$protofile"  || exit $?

names=`grep message "$protofile" | awk '{print $2}'`

# header
cat >"$outfile" <<EOF
// Generated by srpc/pbgen.sh

package $pkgname

import (
	"github.com/golang/protobuf/proto"
)

const (
	_ = iota
EOF

# Output the msg id
for n in $names
do
	echo "\t${n}Id" >> "$outfile"
done

cat >>"$outfile" <<EOF
)

type protobufFactory struct{}

func NewProtobufFactory() PayloadFactory {
	pf := new(protobufFactory)
	return PayloadFactory(pf)
}

func (pf *protobufFactory) New(id uint16) (p Payload) {
	switch id {
EOF

for n in $names
do
	cat >> "$outfile" << EOF
	case ${n}Id:
		p = New${n}()
EOF
done

cat >> "$outfile" << EOF
	}

	return p
}

EOF

for n in $names
do
	cat >>"$outfile" << EOF
func New${n}() *${n} {
	return new(${n})
}

func (p *${n}) GetPayloadId() uint16 {
	return ${n}Id
}

func (p *${n}) MarshalPayload() ([]byte, error) {
	return proto.Marshal(p)
}

func (p *${n}) UnmarshalPayload(b []byte) error {
	return proto.Unmarshal(b, p)
}
EOF
done

